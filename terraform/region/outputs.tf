output "vrack_net" {
  description = "OVH Cloud private network"
  value       = ovh_cloud_project_network_private.net
}

output "keypair" {
  description = "Keypair"
  value       = openstack_compute_keypair_v2.keypair.*
}
