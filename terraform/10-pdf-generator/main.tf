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

resource "kubernetes_namespace" "pdf_generator" {
  metadata {
    name = "pdf-generator"
  }
}

resource "helm_release" "pdf_generator" {  
  name       = "pdf-generator"
  repository = "https://raw.githubusercontent.com/brandonros/hull-wrapper/master/"
  chart      = "hull-wrapper"
  namespace  = "pdf-generator"
  version    = "0.2.0"

  values = [
    <<-EOT
    hull:
      config:
        general:
          nameOverride: pdf-generator
          rbac: false
          noObjectNamePrefixes: true
      objects:
        serviceaccount:
          default:
            enabled: false
        deployment:
          pdf-generator:
            replicas: 4
            annotations:
              linkerd.io/inject: enabled
              config.linkerd.io/proxy-log-level: debug
            pod:
              containers:
                main:
                  resources:
                    requests:
                      memory: 256Mi
                      cpu: 250m
                    limits:
                      memory: 2048Mi
                      cpu: 2000m
                  image:
                    repository: ghcr.io/avdeev99/puppeteer-pdf-generator
                    tag: 93420ed874e6937871ce6a40449a960aa8738e86
                  env:
                    CHROMIUM_PATH:
                      value: /usr/bin/chromium
                    PUPPETEER_MAX_CONCURRENT_PAGES:
                      value: 15
                    ASPNETCORE_URLS:
                      value: http://0.0.0.0:3000
                  ports:
                    http:
                      containerPort: 3000
        service:
          pdf-generator:
            type: ClusterIP
            ports:
              http:
                port: 3000
                targetPort: 3000
    EOT
  ]
}