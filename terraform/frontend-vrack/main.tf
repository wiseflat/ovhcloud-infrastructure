provider "openstack" {
  region = var.region
}

data "openstack_networking_network_v2" "ext_net" {
  name = var.ext_net
}

# network port

resource "openstack_networking_port_v2" "ext_port" {
  count = var.nbinstances

  name               = format("%s%s.%s.%s.%s", var.hostname, format(var.format, count.index + 1), lower(var.region), var.zone.subdomain, var.zone.root)
  network_id         = data.openstack_networking_network_v2.ext_net.id
  admin_state_up     = "true"
  security_group_ids = [var.secgroup.id]
}

resource "openstack_networking_port_v2" "lan_port" {
  count = var.nbinstances

  name           = format("%s%s.%s.%s.%s", var.hostname, format(var.format, count.index + 1), lower(var.region), var.zone.subdomain, var.zone.root)
  network_id     = var.lan_net.id
  admin_state_up = "true"
  fixed_ip {
    subnet_id  = var.lan_subnet.id
    ip_address = cidrhost(var.public_subnet, count.index + 1)
  }
}

## Disks

resource "openstack_blockstorage_volume_v2" "data" {
  count = var.disk ? var.nbinstances : 0

  name = "data"
  size = 10
}

resource "openstack_compute_volume_attach_v2" "data" {
  count = var.disk ? var.nbinstances : 0

  instance_id = openstack_compute_instance_v2.instance.*.id[count.index]
  volume_id   = openstack_blockstorage_volume_v2.data.*.id[count.index]
}

# Instance

data "openstack_images_image_v2" "default" {
  name        = var.image_name
  most_recent = true
}

resource "openstack_compute_instance_v2" "instance" {
  count = var.nbinstances

  name        = format("%s%s.%s.%s.%s", var.hostname, format(var.format, count.index + 1), lower(var.region), var.zone.subdomain, var.zone.root)
  image_id    = data.openstack_images_image_v2.default.id
  flavor_name = var.flavor_name
  key_pair    = var.keypair.id

  network {
    access_network = true
    port           = element(openstack_networking_port_v2.ext_port.*.id, count.index)
  }

  network {
    port = element(openstack_networking_port_v2.lan_port.*.id, count.index)
  }

  network {
    name        = var.vrack_net.name
    fixed_ip_v4 = cidrhost(var.vrack_subnet.network, count.index + 1)
  }

  lifecycle {
    ignore_changes = [user_data, image_id, key_pair]
  }

  metadata = var.metadata

  user_data = var.user_data
}

# Ansible operations

resource "null_resource" "ansible" {
  count = var.ansible ? var.nbinstances : 0

  depends_on = [openstack_compute_instance_v2.instance, openstack_compute_volume_attach_v2.data]

  triggers = {
    hostname      = openstack_compute_instance_v2.instance[count.index].name
    access_ip_v4      = openstack_compute_instance_v2.instance[count.index].access_ip_v4
  }
  
  provisioner "local-exec" {
    command     = "ansible-playbook playbooks/ssh-config.yml -e subdomain=${var.zone.subdomain} -e location=${var.metadata.location} -e server=frontend_vrack -e section=frontend_vrack -e ip=${self.triggers.access_ip_v4} -e hostname=${self.triggers.hostname} -e state=present"
    working_dir = "${path.root}/../.."
  }
  provisioner "local-exec" {
    command     = "ansible-playbook playbooks/check-port.yml -l localhost -e ip=${self.triggers.access_ip_v4} -e checkport=22"
    working_dir = "${path.root}/../.."
  }
  # provisioner "local-exec" {
  #   command     = "ansible-playbook playbooks/check-cloudinit.yml -l ${self.triggers.hostname}"
  #   working_dir = "${path.root}/../.."
  # }
  provisioner "local-exec" {
    command     = "ansible-playbook playbooks/iptables.yml -l ${self.triggers.hostname}"
    working_dir = "${path.root}/../.."
  }
  provisioner "local-exec" {
    command     = "ansible-playbook playbooks/facts.yml -l ${self.triggers.hostname} -e region=${lower(var.region)} -e role=${var.metadata.role}"
    working_dir = "${path.root}/../.."
  }
}

resource "null_resource" "ansible-destroy" {
  count = var.ansible ? var.nbinstances : 0

  triggers = {
    location      = var.metadata.location
    hostname      = openstack_compute_instance_v2.instance[count.index].name
    subdomain     = var.zone.subdomain
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "ansible-playbook playbooks/ssh-config.yml -e subdomain=${self.triggers.subdomain} -e location=${self.triggers.location} -e server=frontend_vrack -e section=frontend_vrack -e ip=null -e hostname=${self.triggers.hostname} -e state=absent"
    working_dir = "${path.root}/../.."
  }
}
