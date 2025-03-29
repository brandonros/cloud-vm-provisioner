variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

resource "kubernetes_namespace" "pdf_generator" {
  metadata {
    name = "pdf-generator"
  }
}

resource "helm_release" "pdf_generator" {  
  depends_on = [
    kubernetes_namespace.pdf_generator,
  ]

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

resource "kubernetes_manifest" "pdf_generator_http_route" {
  depends_on = [
    helm_release.pdf_generator,
  ]

  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: http-to-https-redirect
  namespace: traefik
spec:
  parentRefs:
  - name: http-gateway
    namespace: traefik
    kind: Gateway
  hostnames:
  - ${var.duckdns_domain}
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
YAML
  )
}

resource "kubernetes_manifest" "pdf_generator_https_route" {  
  depends_on = [
    helm_release.pdf_generator,
  ]

  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: pdf-generator-https-route
  namespace: traefik
spec:
  parentRefs:
  - name: https-gateway
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

resource "kubernetes_manifest" "pdf_generator_reference_grant" {  
  depends_on = [
    kubernetes_manifest.pdf_generator_https_route,
  ]

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
      name: pdf-generator-https-route
  to:
    - group: ""
      kind: Service
      name: pdf-generator
YAML
  )
}
