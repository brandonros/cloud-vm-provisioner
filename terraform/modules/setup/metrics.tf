resource "helm_release" "metrics_server" {
  depends_on = [null_resource.setup_ssh]
  
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
} 