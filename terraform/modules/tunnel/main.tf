resource "null_resource" "kubernetes_tunnel" {
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
