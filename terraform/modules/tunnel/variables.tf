variable "instance_ip" {
  type = string
  description = "IP address of the Vultr instance"
}

variable "instance_username" {
  type = string
  description = "Username for SSH connection"
} 

variable "instance_ssh_port" {
  type = number
  description = "SSH port of the Vultr instance"
}
