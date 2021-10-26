resource "ovh_cloud_project_network_private" "net" {
  name         = var.name
  service_name = var.project_id
  regions      = var.regions
  vlan_id      = var.vlan_id
  depends_on   = [var.cloud_project]
}
