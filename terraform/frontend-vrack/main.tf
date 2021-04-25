provider "openstack" {
  region = var.region
}

data "openstack_networking_network_v2" "ext_net" {
  name = var.ext_net
}

# network port

resource "openstack_networking_port_v2" "ext_port" {
  count = var.nbinstances

  name               = format("%s%s.%s.%s.%s.%s", var.hostname, count.index + 1, lower(var.region), var.name, var.zone.subdomain, var.zone.root)
  network_id         = data.openstack_networking_network_v2.ext_net.id
  admin_state_up     = "true"
  security_group_ids = [var.secgroup.id]
}

resource "openstack_networking_port_v2" "lan_port" {
  count = var.nbinstances

  name           = format("%s%s.%s.%s.%s.%s", var.hostname, count.index + 1, lower(var.region), var.name, var.zone.subdomain, var.zone.root)
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

  name        = format("%s%s.%s.%s.%s.%s", var.hostname, count.index + 1, lower(var.region), var.name, var.zone.subdomain, var.zone.root)
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
    fixed_ip_v4 = var.vrack_fixed_ip
  }

  lifecycle {
    ignore_changes = [user_data, image_id, key_pair]
  }

  metadata = var.metadata

  user_data = var.user_data
}

# Ansible operations

resource "null_resource" "ansible" {
  count = var.nbinstances

  depends_on = [openstack_compute_instance_v2.instance, openstack_compute_volume_attach_v2.data]

  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook_path}/ssh-config.yml -e project=${var.zone.subdomain} -e location=${var.metadata.location} -e server=frontend_vrack -e section=frontend_vrack -e ip=${openstack_compute_instance_v2.instance[count.index].access_ip_v4} -e hostname=${openstack_compute_instance_v2.instance[count.index].name} -e state=present"
    working_dir = var.working_dir
  }
  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook_path}/check-port.yml -l localhost -e ip=${openstack_compute_instance_v2.instance[count.index].access_ip_v4} -e checkport=22"
    working_dir = var.working_dir
  }
  # provisioner "local-exec" {
  #   command     = "ansible-playbook ${var.playbook_path}/check-cloudinit.yml -l ${openstack_compute_instance_v2.instance[count.index].name}"
  #   working_dir = var.working_dir
  # }
  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook_path}/iptables.yml -l ${openstack_compute_instance_v2.instance[count.index].name}"
    working_dir = var.working_dir
  }
  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook_path}/facts.yml -l ${openstack_compute_instance_v2.instance[count.index].name} -e region=${var.region} -e role=${var.metadata.role}"
    working_dir = var.working_dir
  }
}

resource "null_resource" "ansible-destroy" {
  count = var.nbinstances

  triggers = {
    location      = var.metadata.location
    hostname      = openstack_compute_instance_v2.instance[count.index].name
    playbook_path = var.playbook_path
    working_dir   = var.working_dir
    subdomain     = var.zone.subdomain
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "ansible-playbook ${self.triggers.playbook_path}/ssh-config.yml -e project=${self.triggers.subdomain} -e location=${self.triggers.location} -e server=frontend_vrack -e section=frontend_vrack -e ip=null -e hostname=${self.triggers.hostname} -e state=absent"
    working_dir = self.triggers.working_dir
  }
}
