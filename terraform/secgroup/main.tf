provider "openstack" {
  region = var.region
}

locals {
  tcp_pairs = [
    for pair in setproduct(
      var.restricted_port,
      var.restricted_ip) : {
      port   = pair[0]
      prefix = pair[1]
    }
  ]
}

resource "openstack_networking_secgroup_v2" "ingress" {
  name        = "${var.name}-net"
  description = "${var.name} net security group"
}

resource "openstack_networking_secgroup_v2" "egress" {
  name        = "${var.name}-lan"
  description = "${var.name} lan security group"
}

# resource "openstack_networking_secgroup_rule_v2" "port_filterd" {
#   count = length(var.restricted_ip)

#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 22
#   port_range_max    = 22
#   remote_ip_prefix  = tolist(var.restricted_ip)[count.index]
#   security_group_id = openstack_networking_secgroup_v2.ingress.id
# }

resource "openstack_networking_secgroup_rule_v2" "port_filterd" {
  for_each = {
    for pair in local.tcp_pairs : "${pair.port}.${pair.prefix}" => pair
  }

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = each.value.port
  port_range_max    = each.value.port
  remote_ip_prefix  = each.value.prefix
  security_group_id = openstack_networking_secgroup_v2.ingress.id
}

resource "openstack_networking_secgroup_rule_v2" "portv4_opened" {
  count = length(var.public_port)

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = tolist(var.public_port)[count.index]
  port_range_max    = tolist(var.public_port)[count.index]
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ingress.id
}

resource "openstack_networking_secgroup_rule_v2" "portv6_opened" {
  count = length(var.public_port)

  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = tolist(var.public_port)[count.index]
  port_range_max    = tolist(var.public_port)[count.index]
  remote_ip_prefix  = "::/0"
  security_group_id = openstack_networking_secgroup_v2.ingress.id
}
