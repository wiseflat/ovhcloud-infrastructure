provider "ovh" {
  endpoint = "ovh-eu"
}

terraform {
  backend "swift" {
    container         = "monoregion-terraform-state"
    archive_container = "monoregion-terraform-state-archive"
    region_name       = "GRA"
  }
}

resource "ovh_vrack_cloudproject" "attach" {
  vrack_id   = var.vrack_id
  project_id = var.project_id
}

module "domains" {
  source = "/drone/src/terraform//domain"

  domains = var.domains
}

module "region" {
  source = "/drone/src/terraform//region"

  name           = var.name
  project_id     = var.project_id
  regions        = var.regions
  vlan_id        = var.vlan_id
  cloud_project  = ovh_vrack_cloudproject.attach
  ssh_public_key = file(var.ssh_public_key)
}

module "secgroup" {
  source = "/drone/src/terraform//secgroup"

  name            = var.name
  region          = element(tolist(var.regions), 0)
  restricted_ip   = var.restricted_ip
  restricted_port = var.restricted_port
  public_port     = var.public_port
}

module "network" {
  source = "/drone/src/terraform//network"

  name    = var.network_name
  ext_net = "Ext-Net"
  lan_net = element(tolist(var.frontends.lan_net), 0)
  region  = element(tolist(var.regions), 0)

  project_id    = var.project_id
  cloud_project = ovh_vrack_cloudproject.attach
  vrack_net     = module.region.vrack_net
}

data "template_file" "frontend" {
  template = <<EOF
#cloud-config
output: { all: "| tee -a /var/log/cloud-init-output.log" }
package_update: true
packages:
 - htop
 - net-tools
ssh_authorized_keys:
  ${file(var.ssh_public_key)}
write_files:
-   content: |
      network:
        ethernets:
          ens4:
            dhcp4: true
            match:
              name: ens4
            set-name: ens4
        version: 2
    path: /etc/netplan/60-cloud-init.yaml
runcmd:
 - netplan apply
 - touch /tmp/cloudinit
EOF
}

module "frontend" {
  source = "/drone/src/terraform//frontend"

  secgroup = module.secgroup.ingress

  ext_net    = "Ext-Net"
  lan_net    = module.network.lan_net
  lan_subnet = module.network.lan_subnet

  region        = element(tolist(var.regions), 0)
  public_subnet = element(tolist(var.frontends.lan_net), 0)

  name     = var.name
  hostname = var.frontends.hostname
  zone     = var.zone

  nbinstances = var.frontends.nbinstances
  keypair     = element(tolist(module.region.keypair), 0)
  image_name  = var.frontends.image
  flavor_name = var.frontends.flavor
  disk        = var.frontends.disk
  disk_size   = var.frontends.disk_size
  user_data   = data.template_file.frontend.template

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "frontend"
    location = "monoregion"
  }
}

data "template_file" "backend" {
  template = <<EOF
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
            gateway4: ${cidrhost(element(tolist(var.frontends.lan_net), 0), 1)}
        version: 2
    path: /etc/netplan/50-cloud-init.yaml
runcmd:
 - netplan apply
 - touch /tmp/cloudinit
EOF
}

module "backend" {
  source = "/drone/src/terraform//backend"

  region     = element(tolist(var.regions), 0)
  lan_net    = module.network.lan_net
  lan_subnet = module.network.lan_subnet

  name     = var.name
  hostname = var.backends.hostname
  zone     = var.zone

  nbinstances = var.backends.nbinstances
  keypair     = element(tolist(module.region.keypair), 0)
  image_name  = var.backends.image
  flavor_name = var.backends.flavor
  disk        = var.backends.disk
  disk_size   = var.backends.disk_size
  user_data   = data.template_file.backend.template

  frontend_hostname = format("%s%s.%s.%s.%s.%s", var.frontends.hostname, 1, lower(element(tolist(var.regions), 0)), var.name, var.zone.subdomain, var.zone.root)

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "backend"
    location = "monoregion"
  }
}
