variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}


resource "kubernetes_manifest" "http_gateway" {
  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: http-gateway
  namespace: traefik
spec:
  gatewayClassName: traefik
  listeners:
    - name: domain-http
      hostname: ${var.duckdns_domain}
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
  name: letsencrypt-prod-issuer
  namespace: traefik
spec:
  acme:
    email: test@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
            - name: http-gateway
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
  name: domain-prod-tls
  namespace: traefik
spec:
  secretName: domain-prod-tls
  issuerRef:
    name: letsencrypt-prod-issuer
    kind: Issuer
  dnsNames:
  - ${var.duckdns_domain}
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
  name: https-gateway
  namespace: traefik
  annotations:
    cert-manager.io/issuer: letsencrypt-prod-issuer
spec:
  gatewayClassName: traefik
  listeners:
    - name: domain-https
      hostname: ${var.duckdns_domain}
      port: 8443
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
