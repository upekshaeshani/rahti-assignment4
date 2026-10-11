output "vm_name" {
  description = "Name of the OpenTofu-created VM"
  value       = openstack_compute_instance_v2.web.name
}

output "floating_ip" {
  description = "Public floating IP address of the web server"
  value       = openstack_networking_floatingip_v2.web_ip.address
}

output "instance_id" {
  description = "OpenStack instance ID"
  value       = openstack_compute_instance_v2.web.id
}