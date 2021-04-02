output "lan_net" {
  description = "The definition of the lan network"
  value       = openstack_networking_network_v2.lan_net
}

output "lan_subnet" {
  description = "The definition of the frontends lan subnet"
  value       = openstack_networking_subnet_v2.lan_subnet
}

output "vrack_subnet" {
  description = "The definition of the OVH vrack network subnet"
  value       = ovh_cloud_project_network_private_subnet.vrack_subnet
}
