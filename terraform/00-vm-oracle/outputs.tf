output "instance_username" {
  value = "ubuntu"  # Default username for Ubuntu instances in OCI
}

output "instance_ipv4" {
  value = oci_core_instance.free_instance.public_ip
}

output "ssh_port" {
  value = 22
}
