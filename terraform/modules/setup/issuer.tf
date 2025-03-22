resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  depends_on = [
    helm_release.traefik,
    helm_release.duckdns_updater
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
            - name: gateway
              namespace: traefik
              kind: Gateway
YAML
  )
}
