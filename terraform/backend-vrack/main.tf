
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

  name        = format("%s%s.%s.%s.%s.%s", var.hostname, count.index + 1, lower(var.region), var.name, var.zone.subdomain, var.zone.root)
  image_id    = data.openstack_images_image_v2.default.id
  flavor_name = var.flavor_name

  key_pair = var.keypair.id

  network {
    name = var.lan_net.name
  }

  # lifecycle {
  #   ignore_changes = [user_data, image_id, key_pair]
  # }

  metadata = var.metadata

  user_data = <<EOF
#cloud-config
output: { all: "| tee -a /var/log/cloud-init-output.log" }
package_update: false
ssh_authorized_keys:
  ${var.ssh_public_key}
write_files:
-   content: |
      network:
        ethernets:
          ens3:
            dhcp4: true
            match:
              name: ens3
            set-name: ens3
            gateway4: ${var.gateway}
            nameservers:
              addresses: ${jsonencode(var.dns_nameservers)}
        version: 2
    path: /etc/netplan/50-cloud-init.yaml
runcmd:
 - netplan apply
 - touch /tmp/cloudinit
EOF
}

# Ansible operations

resource "null_resource" "ansible" {
  count = var.nbinstances

  depends_on = [openstack_compute_instance_v2.instance, openstack_compute_volume_attach_v2.data]

  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook_path}/ssh-config.yml -e project=${var.zone.subdomain} -e section=backend_vrack -e location=${var.metadata.location} -e server=backend_vrack -e ip=${openstack_compute_instance_v2.instance[count.index].access_ip_v4} -e hostname=${openstack_compute_instance_v2.instance[count.index].name} -e proxyjump=${format("%s%s.%s.%s.%s.%s", "frontend", 1, lower(var.region), var.name, var.zone.subdomain, var.zone.root)} -e state=present"
    working_dir = var.working_dir
  }
  provisioner "local-exec" {
    command     = "ansible-playbook ${var.playbook_path}/check-port.yml -l ${var.frontend_hostname} -e ip=${openstack_compute_instance_v2.instance[count.index].access_ip_v4} -e checkport=22"
    working_dir = var.working_dir
  }
  # provisioner "local-exec" {
  #   command     = "ansible-playbook ${var.playbook_path}/check-cloudinit.yml -l ${openstack_compute_instance_v2.instance[count.index].name}"
  #   working_dir = var.working_dir
  # }
}

resource "null_resource" "ansible-destroy" {
  count = var.nbinstances

  depends_on = [openstack_compute_instance_v2.instance, openstack_compute_volume_attach_v2.data]

  triggers = {
    location      = var.metadata.location
    hostname      = openstack_compute_instance_v2.instance[count.index].name
    playbook_path = var.playbook_path
    working_dir   = var.working_dir
    subdomain     = var.zone.subdomain
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "ansible-playbook ${self.triggers.playbook_path}/ssh-config.yml -e project=${self.triggers.subdomain} -e location=${self.triggers.location} -e server=backend_vrack -e section=backend_vrack -e ip=null -e proxyjump=null -e hostname=${self.triggers.hostname} -e state=absent"
    working_dir = self.triggers.working_dir
  }
}
