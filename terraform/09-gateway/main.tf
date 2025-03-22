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

variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

resource "kubernetes_manifest" "gateway" {  
  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway
  namespace: traefik
  annotations:
    cert-manager.io/issuer: letsencrypt-prod-issuer
spec:
  gatewayClassName: traefik
  listeners:
    - name: domain-http
      hostname: ${var.duckdns_domain}
      port: 8000 # must match exposed port in traefik chart
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
    - name: domain-https
      hostname: ${var.duckdns_domain}
      port: 8443 # must match exposed port in traefik chart
      protocol: HTTPS
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: domain-prod-tls
YAML
  )
}
