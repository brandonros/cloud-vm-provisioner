output "kubeconfig_path" {
  description = "Path to the kubeconfig file for the k3s cluster"
  value       = abspath(local_file.kubeconfig_file.filename)
}