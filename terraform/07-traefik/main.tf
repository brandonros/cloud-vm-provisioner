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

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {
  depends_on = [
    kubernetes_namespace.traefik
  ]
  
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = "traefik"
  version    = "34.4.0"

  values = [
    <<-EOT
    ports:
      web:
        port: 8000
        expose:
          default: true
        exposedPort: 80
        protocol: TCP
      websecure:
        port: 8443
        expose:
          default: true
        exposedPort: 443
        protocol: TCP
        tls:
          enabled: true
    
    gateway:
      enabled: false

    deployment:
      podAnnotations:
        linkerd.io/inject: enabled
        config.linkerd.io/proxy-log-level: debug

    logs:
      general:
        level: TRACE
      access:
        enabled: true

    providers:
      kubernetesIngress:
        enabled: false
      kubernetesGateway:
        enabled: true
    EOT
  ]
} 

