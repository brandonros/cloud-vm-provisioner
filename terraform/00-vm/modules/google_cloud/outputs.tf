output "instance_username" {
  value = var.os_login_user_id
}

output "instance_ipv4" {
  value = google_compute_instance.my_instance.network_interface[0].access_config[0].nat_ip
}

output "ssh_port" {
  value = 22
}
