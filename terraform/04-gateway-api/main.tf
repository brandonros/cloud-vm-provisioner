variable "instance_username" {
  type = string
  description = "Username for SSH connection"
} 

variable "instance_ip" {
  type = string
  description = "IP address of the Vultr instance"
}

resource "null_resource" "install_gateway_api" {
  provisioner "remote-exec" {
    script = "${path.module}/install-gateway-api.sh"

    connection {
      type        = "ssh"
      user        = var.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = var.instance_ip
    }
  }
}
