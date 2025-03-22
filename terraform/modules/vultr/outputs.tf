output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = vultr_instance.my_instance.main_ip
}

output "instance_ssh_port" {
  value = 22
}
