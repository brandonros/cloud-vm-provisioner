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

resource "null_resource" "fetch_kubeconfig2" {
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

  # Add new provisioner for SSH tunnel
  provisioner "local-exec" {
    command = <<-EOT
      if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
        if ! pgrep -f "ssh.*-L 6443:localhost:6443.*${var.instance_ip}" > /dev/null; then
          echo "Starting SSH tunnel..."
          ssh -fN -L 6443:localhost:6443 ${var.instance_username}@${var.instance_ip} &
          echo $! > ${path.module}/../../../server-files/ssh_tunnel.pid
        else
          echo "SSH tunnel already running"
        fi
      else
        echo "Windows SSH tunnel setup not implemented"
      fi
    EOT
  }

  # Add cleanup provisioner
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      if [ -f ${path.module}/../../../server-files/ssh_tunnel.pid ]; then
        pid=$(cat ${path.module}/../../../server-files/ssh_tunnel.pid)
        kill $pid || true
        rm ${path.module}/../../../server-files/ssh_tunnel.pid
      fi
    EOT
  }
}
