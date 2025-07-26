output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = local.split_vm_info[0]
}

output "instance_ssh_port" {
  value = local.split_vm_info[1]
}
