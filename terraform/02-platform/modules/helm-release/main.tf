variable "manifest" {
  description = "The parsed manifest configuration"
  type = object({
    metadata = object({
      name      = string
      namespace = string
    })
    spec = object({
      repo           = string
      chart          = string
      version        = string
      valuesContent  = string
    })
  })
}

resource "helm_release" "release" {  
  name       = var.manifest.metadata.name
  repository = var.manifest.spec.repo
  chart      = var.manifest.spec.chart
  namespace  = var.manifest.spec.targetNamespace
  version    = var.manifest.spec.version
  values = [
    var.manifest.spec.valuesContent
  ]
  create_namespace = true
  wait_for_jobs = true
}
