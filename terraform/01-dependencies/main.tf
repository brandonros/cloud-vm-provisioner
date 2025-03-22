resource "null_resource" "dependencies" {
  provisioner "remote-exec" {
    script = "${path.module}/../../scripts/dependencies.sh"

    connection {
      type        = "ssh"
      user        = var.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = var.instance_ip
    }
  }
}

resource "null_resource" "k3s" {
  depends_on = [null_resource.dependencies]

  provisioner "remote-exec" {
    script = "${path.module}/../../scripts/k3s.sh"

    connection {
      type        = "ssh"
      user        = var.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = var.instance_ip
    }
  }
}

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.k3s]

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/../../server-files
      scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ${var.instance_username}@${var.instance_ip}:/home/debian/.kube/config ${path.module}/../../server-files/kubeconfig
    EOT
  }
}
