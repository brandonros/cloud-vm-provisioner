output "kubeconfig" {
  value = local.kubeconfig_content
  sensitive = true  # Mark as sensitive since it contains credentials
}

output "kubeconfig_path" {
  value = abspath(local_file.kubeconfig_file.filename)
  description = "Path to the kubeconfig file"
}
