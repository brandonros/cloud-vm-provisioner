locals {
  manifest = yamldecode(file("${path.module}/manifest.yaml"))
}

resource "helm_release" "metrics_server" {  
  name       = local.manifest.metadata.name
  repository = local.manifest.spec.repo
  chart      = local.manifest.spec.chart
  namespace  = local.manifest.metadata.namespace
  version    = local.manifest.spec.version
  values = [
    local.manifest.spec.valuesContent
  ]
}
