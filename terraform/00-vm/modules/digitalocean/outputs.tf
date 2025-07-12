output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = digitalocean_droplet.droplet1.ipv4_address
}

output "ssh_port" {
  value = 22
}
