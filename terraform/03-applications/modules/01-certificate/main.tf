variable "domain" {
  type = string
  description = "Domain"
}

variable "app_name" {
  type = string
  description = "Application name"
}

resource "kubernetes_manifest" "http_gateway" {
  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: ${var.app_name}-http-gateway
  namespace: traefik
spec:
  gatewayClassName: traefik
  listeners:
    - name: ${var.app_name}-http
      hostname: ${var.domain}
      port: 8000
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
YAML
  )
}

resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  depends_on = [
    kubernetes_manifest.http_gateway,
  ]

  manifest = yamldecode(<<YAML
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ${var.app_name}-letsencrypt-prod-issuer
  namespace: traefik
spec:
  acme:
    email: test@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: ${var.app_name}-letsencrypt-prod-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
            - name: ${var.app_name}-http-gateway
              namespace: traefik
              kind: Gateway
YAML
  )
}

resource "kubernetes_manifest" "domain_prod_tls_certificate" {
  depends_on = [
    kubernetes_manifest.letsencrypt_prod_issuer,
  ]

  timeouts {
    create = "10m"
    update = "10m"
  }

  manifest = yamldecode(<<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${var.app_name}-prod-tls
  namespace: traefik
spec:
  secretName: ${var.app_name}-prod-tls
  issuerRef:
    name: ${var.app_name}-letsencrypt-prod-issuer
    kind: Issuer
  dnsNames:
  - ${var.domain}
YAML
  )
}

resource "kubernetes_manifest" "https_gateway" {
  depends_on = [
    kubernetes_manifest.domain_prod_tls_certificate,
  ]

  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: ${var.app_name}-https-gateway
  namespace: traefik
  annotations:
    cert-manager.io/issuer: ${var.app_name}-letsencrypt-prod-issuer
spec:
  gatewayClassName: traefik
  listeners:
    - name: ${var.app_name}-https
      hostname: ${var.domain}
      port: 8443
      protocol: HTTPS
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: ${var.app_name}-prod-tls
YAML
  )
}
