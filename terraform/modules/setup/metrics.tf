resource "helm_release" "metrics_server" {
  depends_on = [null_resource.fetch_kubeconfig2]
  
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
} 