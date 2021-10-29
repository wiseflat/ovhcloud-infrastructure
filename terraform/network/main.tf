provider "openstack" {
  region = var.region
}

# Public network

data "openstack_networking_network_v2" "ext_net" {
  name = var.ext_net
}

# Private network

resource "openstack_networking_network_v2" "lan_net" {
  name           = var.name
  admin_state_up = "true"
  depends_on = [
    var.cloud_project
  ]
}

## Network subnet of the frontend instances

resource "openstack_networking_subnet_v2" "lan_subnet" {
  name            = "${var.name}-subnet"
  network_id      = openstack_networking_network_v2.lan_net.id
  cidr            = var.lan_net
  ip_version      = 4
  enable_dhcp     = true
  no_gateway      = true
  dns_nameservers = var.dns_nameservers

  allocation_pool {
    start = cidrhost(var.lan_net, -10)
    end   = cidrhost(var.lan_net, -2)
  }
}
