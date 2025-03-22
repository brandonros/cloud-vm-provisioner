terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.module}/../../server-files/kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/../../server-files/kubeconfig"
  }
}

variable "instance_username" {
  type = string
  description = "Username for SSH connection"
} 

variable "instance_ip" {
  type = string
  description = "IP address of the Vultr instance"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "null_resource" "install_gateway_api" {
  provisioner "remote-exec" {
    script = "${path.module}/../../scripts/install-gateway-api.sh"

    connection {
      type        = "ssh"
      user        = var.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = var.instance_ip
    }
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [
    kubernetes_namespace.cert_manager,
    null_resource.install_gateway_api,
  ]
  
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.15.3"

  values = [
    <<-EOT
    crds:
        enabled: true
    config:
      apiVersion: controller.config.cert-manager.io/v1alpha1
      kind: ControllerConfiguration
      enableGatewayAPI: true
    EOT
  ]
} 
