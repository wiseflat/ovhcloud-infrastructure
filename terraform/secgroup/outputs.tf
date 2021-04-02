output "ingress" {
  description = ""
  value       = openstack_networking_secgroup_v2.ingress
}

output "egress" {
  description = ""
  value       = openstack_networking_secgroup_v2.egress
}
