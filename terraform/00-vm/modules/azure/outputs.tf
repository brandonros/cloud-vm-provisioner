output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = azurerm_public_ip.public_ip1.ip_address
}

output "instance_ssh_port" {
  value = 22
}
