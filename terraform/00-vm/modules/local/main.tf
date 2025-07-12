terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

resource "null_resource" "local_stub" {
  provisioner "local-exec" {
    command = "echo 'stub'"
  }
}
