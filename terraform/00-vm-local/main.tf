resource "null_resource" "local_stub" {
  provisioner "local-exec" {
    command = "echo 'stub'"
  }
}
