variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

resource "kubernetes_manifest" "pdf_generator_reference_grant" {  
  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-traefik-to-pdf-generator
  namespace: pdf-generator
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: traefik
  to:
    - group: ""
      kind: Service
YAML
  )
}

resource "kubernetes_manifest" "pdf_generator_httproute" {  
  depends_on = [
    kubernetes_manifest.pdf_generator_reference_grant,
  ]

  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: pdf-generator-httproute
  namespace: traefik
spec:
  parentRefs:
  - name: gateway
    namespace: traefik
    kind: Gateway
    sectionName: domain-https
  hostnames:
  - ${var.duckdns_domain}
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: pdf-generator
      namespace: pdf-generator
      port: 3000
      kind: Service
      weight: 100
YAML
  )
}