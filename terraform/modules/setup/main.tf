resource "null_resource" "setup" {
  provisioner "remote-exec" {
    script = "${path.module}/../../../scripts/setup.sh"

    connection {
      type        = "ssh"
      user        = var.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = var.instance_ip
    }
  }
}
