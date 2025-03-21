output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = vultr_instance.my_instance.main_ip
}

output "ssh_port" {
  value = 22
}
