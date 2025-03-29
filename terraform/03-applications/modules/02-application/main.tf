variable "domain" {
  type = string
  description = "Domain"
}

variable "app_name" {
  type = string
  description = "Application name"
} 

variable "helm_values" {
  type = any
  description = "Full Helm values configuration"
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_name
  }
}

resource "helm_release" "app" {  
  depends_on = [
    kubernetes_namespace.app,
  ]

  name       = var.app_name
  repository = "https://raw.githubusercontent.com/brandonros/hull-wrapper/master/"
  chart      = "hull-wrapper"
  namespace  = var.app_name
  version    = "0.2.0"

  values = [
    yamlencode(var.helm_values)
  ]
}

resource "kubernetes_manifest" "app_http_route" {
  depends_on = [
    helm_release.app,
  ]

  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: ${var.app_name}-http-to-https-redirect
  namespace: traefik
spec:
  parentRefs:
  - name: ${var.app_name}-http-gateway
    namespace: traefik
    kind: Gateway
  hostnames:
  - ${var.domain}
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
YAML
  )
}

resource "kubernetes_manifest" "app_https_route" {  
  depends_on = [
    helm_release.app,
  ]

  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: ${var.app_name}-https-route
  namespace: traefik
spec:
  parentRefs:
  - name: ${var.app_name}-https-gateway
    namespace: traefik
    kind: Gateway
    sectionName: ${var.app_name}-https
  hostnames:
  - ${var.domain}
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: ${var.app_name}
      namespace: ${var.app_name}
      port: ${var.helm_values.hull.objects.deployment[var.app_name].pod.containers.main.ports.http.containerPort}
      kind: Service
      weight: 100
YAML
  )
}

resource "kubernetes_manifest" "app_reference_grant" {  
  depends_on = [
    kubernetes_manifest.app_https_route,
  ]

  manifest = yamldecode(<<YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: ${var.app_name}-reference-grant
  namespace: ${var.app_name}
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: traefik
      name: ${var.app_name}-https-route
  to:
    - group: ""
      kind: Service
      name: ${var.app_name}
YAML
  )
}
