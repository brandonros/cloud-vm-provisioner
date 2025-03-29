variable "duckdns_token" {
  type = string
  description = "DuckDNS token"
}

variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

variable "app_name" {
  type = string
  description = "Application name"
}

resource "kubernetes_namespace" "duckdns_updater" {
  metadata {
    name = "${var.app_name}-duckdns-updater"
  }
}

# Create a Kubernetes secret for the DuckDNS token
resource "kubernetes_secret" "duckdns_token" {
  depends_on = [
    kubernetes_namespace.duckdns_updater,
  ]

  metadata {
    name      = "duckdns-token"
    namespace = "${var.app_name}-duckdns-updater"
  }

  data = {
    token = var.duckdns_token
  }
}

resource "helm_release" "duckdns_updater" {
  depends_on = [
    kubernetes_namespace.duckdns_updater,
    kubernetes_secret.duckdns_token,
  ]
  
  name       = "${var.app_name}-duckdns-updater"
  repository = "https://raw.githubusercontent.com/brandonros/hull-wrapper/master/"
  chart      = "hull-wrapper"
  namespace  = "${var.app_name}-duckdns-updater"
  version    = "0.2.0"
  wait_for_jobs = true

  values = [
    <<-EOT
    hull:
      config:
        general:
          nameOverride: ${var.app_name}-duckdns-updater
          rbac: false
          noObjectNamePrefixes: true
      objects:
        serviceaccount:
          default:
            enabled: false
        job:
          ${var.app_name}-duckdns-updater:
            enabled: true
            pod:
              containers:
                main:
                  image:
                    repository: curlimages/curl
                    tag: latest
                  command:
                    - /bin/sh
                    - -c
                  args:
                    - |
                      echo "Updating DuckDNS record for $DUCKDNS_DOMAIN..."
                      response=$(curl -sSL "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN")
                      if [ "$response" = "OK" ]; then
                          echo "Successfully updated DuckDNS record"
                          exit 0
                      else
                          echo "Failed to update DuckDNS record. response: $response"
                          exit 1
                      fi
                  env:
                    DUCKDNS_DOMAIN:
                      value: ${var.duckdns_domain}
                    DUCKDNS_TOKEN:
                      valueFrom:
                        secretKeyRef:
                          name: duckdns-token
                          key: token
              restartPolicy: Never 
    EOT
  ]
}
