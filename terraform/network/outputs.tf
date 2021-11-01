output "lan_net" {
  description = "The definition of the lan network"
  value       = openstack_networking_network_v2.lan_net
}

output "lan_subnet" {
  description = "The definition of the frontends lan subnet"
  value       = openstack_networking_subnet_v2.lan_subnet
}
