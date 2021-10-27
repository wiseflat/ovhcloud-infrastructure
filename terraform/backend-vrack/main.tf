
provider "openstack" {
  region = var.region
}

## Disks

resource "openstack_blockstorage_volume_v2" "data" {
  count = var.disk ? var.nbinstances : 0

  name = "data"
  size = var.disk_size
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

  key_pair = var.keypair.id

  network {
    name = var.lan_net.name
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
    command     = "ansible-playbook playbooks/ssh-config.yml -e subdomain=${var.zone.subdomain} -e section=backend_vrack -e location=${var.metadata.location} -e server=backend_vrack -e ip=${self.triggers.access_ip_v4} -e hostname=${self.triggers.hostname} -e proxyjump=${format("%s%s.%s.%s.%s", "frontend", format(var.format, 1), lower(var.region), var.zone.subdomain, var.zone.root)} -e state=present"
    working_dir = "${path.root}/../.."
  }
  provisioner "local-exec" {
    command     = "ansible-playbook playbooks/check-port.yml -l ${var.frontend_hostname} -e ip=${self.triggers.access_ip_v4} -e checkport=22"
    working_dir = "${path.root}/../.."
  }
  provisioner "local-exec" {
    command     = "ansible-playbook playbooks/facts.yml -l ${self.triggers.hostname} -e region=${lower(var.region)} -e role=${var.metadata.role}"
    working_dir = "${path.root}/../.."
  }
  # provisioner "local-exec" {
  #   command     = "ansible-playbook playbooks/check-cloudinit.yml -l ${self.triggers.hostname}"
  #   working_dir = "${path.root}/../.."
  # }
}

resource "null_resource" "ansible-destroy" {
  count = var.ansible ? var.nbinstances : 0

  depends_on = [openstack_compute_instance_v2.instance, openstack_compute_volume_attach_v2.data]

  triggers = {
    location      = var.metadata.location
    hostname      = openstack_compute_instance_v2.instance[count.index].name
    subdomain     = var.zone.subdomain
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "ansible-playbook playbooks/ssh-config.yml -e subdomain=${self.triggers.subdomain} -e location=${self.triggers.location} -e server=backend_vrack -e section=backend_vrack -e ip=null -e proxyjump=null -e hostname=${self.triggers.hostname} -e state=absent"
    working_dir = "${path.root}/../.."
  }
}
