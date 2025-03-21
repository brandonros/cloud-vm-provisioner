resource "null_resource" "setup_ssh" {
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

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.setup_ssh]
  
  provisioner "remote-exec" {
    inline = [
      "test -f /home/debian/.kube/config || echo 'Kubeconfig not found!'"
    ]
    
    connection {
      type        = "ssh"
      user        = var.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = var.instance_ip
    }
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/../../../server-files
      scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ${var.instance_username}@${var.instance_ip}:/home/debian/.kube/config ${path.module}/../../../server-files/kubeconfig
    EOT
  }
}
