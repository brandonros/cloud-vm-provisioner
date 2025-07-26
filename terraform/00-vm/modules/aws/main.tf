terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.72.1"
    }
  }
}


resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_route_table" "rtb1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb1.id
}

resource "aws_security_group" "security_group1" {
  name        = "security_group1"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"] # Debian
}

resource "aws_key_pair" "my_ssh_key" {
  key_name   = "my_ssh_key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "virtual_machine1" {
  ami                         = data.aws_ami.debian.id
  instance_type              = "t3.xlarge" # 4 vCPUs, 16.0 GiB, $0.1664/hr
  key_name                   = aws_key_pair.my_ssh_key.key_name
  subnet_id                  = aws_subnet.subnet1.id
  vpc_security_group_ids     = [aws_security_group.security_group1.id]
  associate_public_ip_address = true
  
  # Add spot instance configuration
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.17"
    }
  }
}

output "instance_username" {
  value = "admin"
}

output "instance_ipv4" {
  value = aws_instance.virtual_machine1.public_ip
}

output "ssh_port" {
  value = 22
}
