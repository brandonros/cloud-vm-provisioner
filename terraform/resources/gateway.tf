resource "kubernetes_manifest" "gateway" {
  depends_on = [
    kubernetes_manifest.letsencrypt_prod_issuer,
  ]
  
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
