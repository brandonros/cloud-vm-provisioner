output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = hcloud_server.server1.ipv4_address
}

output "ssh_port" {
  value = 22
}
