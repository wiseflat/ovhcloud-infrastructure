resource "ovh_cloud_project_network_private" "net" {
  name         = var.name
  service_name = var.project_id
  regions      = var.regions
  vlan_id      = var.vlan_id
  depends_on   = [var.cloud_project]
}

resource "openstack_compute_keypair_v2" "keypair" {
  count      = length(var.regions)
  name       = "keypair-${var.name}-${lower(element(var.regions, count.index))}"
  public_key = var.ssh_public_key
  region     = element(var.regions, count.index)
}
