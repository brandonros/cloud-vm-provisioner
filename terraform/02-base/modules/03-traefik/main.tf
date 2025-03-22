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

