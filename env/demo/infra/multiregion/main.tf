provider "ovh" {
  endpoint = "ovh-eu"
}

terraform {
  backend "swift" {
    container         = "multiregion-terraform-state"
    archive_container = "multiregion-terraform-state-archive"
    region_name       = "GRA"
  }
}

resource "ovh_vrack_cloudproject" "attach" {
  vrack_id   = var.vrack_id
  project_id = var.project_id
}

module "domains" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//domain"

  domains = var.domains
}

module "region" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//region"

  name           = var.name
  project_id     = var.project_id
  regions        = var.regions
  vlan_id        = var.vlan_id
  cloud_project  = ovh_vrack_cloudproject.attach
  ssh_public_key = file(var.ssh_public_key)
}

module "secgroup-region-0" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//secgroup"

  name            = var.name
  region          = element(tolist(var.regions), 0)
  restricted_ip   = var.restricted_ip
  restricted_port = var.restricted_port
  public_port     = var.public_port
}

module "secgroup-region-1" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//secgroup"

  name            = var.name
  region          = element(tolist(var.regions), 1)
  restricted_ip   = var.restricted_ip
  restricted_port = var.restricted_port
  public_port     = var.public_port
}

module "secgroup-region-2" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//secgroup"

  name            = var.name
  region          = element(tolist(var.regions), 2)
  restricted_ip   = var.restricted_ip
  restricted_port = var.restricted_port
  public_port     = var.public_port
}

module "network-region-0" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//network"

  name    = var.network_name
  ext_net = "Ext-Net"
  lan_net = element(tolist(var.frontends.lan_net), 0)
  region  = element(tolist(var.regions), 0)

  project_id    = var.project_id
  cloud_project = ovh_vrack_cloudproject.attach
  vrack_net     = module.region.vrack_net
}

module "network-region-1" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//network"

  name    = var.network_name
  ext_net = "Ext-Net"
  lan_net = element(tolist(var.frontends.lan_net), 1)
  region  = element(tolist(var.regions), 1)

  project_id    = var.project_id
  cloud_project = ovh_vrack_cloudproject.attach
  vrack_net     = module.region.vrack_net
}

module "network-region-2" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//network"

  name    = var.network_name
  ext_net = "Ext-Net"
  lan_net = element(tolist(var.frontends.lan_net), 2)
  region  = element(tolist(var.regions), 2)

  project_id    = var.project_id
  cloud_project = ovh_vrack_cloudproject.attach
  vrack_net     = module.region.vrack_net
}


module "frontend-0" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//frontend"

  secgroup = module.secgroup-region-0.ingress

  ext_net    = "Ext-Net"
  lan_net    = module.network-region-0.lan_net
  lan_subnet = module.network-region-0.lan_subnet

  region        = element(tolist(var.regions), 0)
  public_subnet = element(tolist(var.frontends.lan_net), 0)

  name     = var.name
  hostname = var.frontends.hostname
  zone     = var.zone

  nbinstances    = var.frontends.nbinstances
  keypair        = element(tolist(module.region.keypair), 0)
  image_name     = var.frontends.image
  flavor_name    = var.frontends.flavor
  ssh_public_key = file(var.ssh_public_key)
  disk           = var.frontends.disk
  disk_size      = var.frontends.disk_size

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "frontend"
    location = "multiregion"
  }
}

module "frontend-1" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//frontend"

  secgroup = module.secgroup-region-1.ingress

  ext_net    = "Ext-Net"
  lan_net    = module.network-region-1.lan_net
  lan_subnet = module.network-region-1.lan_subnet

  region        = element(tolist(var.regions), 1)
  public_subnet = element(tolist(var.frontends.lan_net), 1)

  name     = var.name
  hostname = var.frontends.hostname
  zone     = var.zone

  nbinstances    = var.frontends.nbinstances
  keypair        = element(tolist(module.region.keypair), 1)
  image_name     = var.frontends.image
  flavor_name    = var.frontends.flavor
  ssh_public_key = file(var.ssh_public_key)
  disk           = var.frontends.disk
  disk_size      = var.frontends.disk_size

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "frontend"
    location = "multiregion"
  }
}

module "frontend-2" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//frontend"

  secgroup = module.secgroup-region-2.ingress

  ext_net    = "Ext-Net"
  lan_net    = module.network-region-2.lan_net
  lan_subnet = module.network-region-2.lan_subnet

  region        = element(tolist(var.regions), 2)
  public_subnet = element(tolist(var.frontends.lan_net), 2)

  name     = var.name
  hostname = var.frontends.hostname
  zone     = var.zone

  nbinstances    = var.frontends.nbinstances
  keypair        = element(tolist(module.region.keypair), 2)
  image_name     = var.frontends.image
  flavor_name    = var.frontends.flavor
  ssh_public_key = file(var.ssh_public_key)
  disk           = var.frontends.disk
  disk_size      = var.frontends.disk_size

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "frontend"
    location = "multiregion"
  }
}

module "backend-0" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//backend"

  region     = element(tolist(var.regions), 0)
  lan_net    = module.network-region-0.lan_net
  lan_subnet = module.network-region-0.lan_subnet
  gateway    = cidrhost(element(tolist(var.frontends.lan_net), 0), 1)

  name     = var.name
  hostname = var.backends.hostname
  zone     = var.zone

  nbinstances    = var.backends.nbinstances
  keypair        = element(tolist(module.region.keypair), 0)
  image_name     = var.backends.image
  flavor_name    = var.backends.flavor
  ssh_public_key = file(var.ssh_public_key)
  disk           = var.backends.disk
  disk_size      = var.backends.disk_size

  frontend_hostname = format("%s%s.%s.%s.%s.%s", var.frontends.hostname, 1, lower(element(tolist(var.regions), 0)), var.name, var.zone.subdomain, var.zone.root)

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "backend"
    location = "multiregion"
  }
}

module "backend-1" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//backend"

  region     = element(tolist(var.regions), 1)
  lan_net    = module.network-region-1.lan_net
  lan_subnet = module.network-region-1.lan_subnet
  gateway    = cidrhost(element(tolist(var.frontends.lan_net), 1), 1)

  name     = var.name
  hostname = var.backends.hostname
  zone     = var.zone

  nbinstances    = var.backends.nbinstances
  keypair        = element(tolist(module.region.keypair), 1)
  image_name     = var.backends.image
  flavor_name    = var.backends.flavor
  ssh_public_key = file(var.ssh_public_key)
  disk           = var.backends.disk
  disk_size      = var.backends.disk_size

  frontend_hostname = format("%s%s.%s.%s.%s.%s", var.frontends.hostname, 1, lower(element(tolist(var.regions), 1)), var.name, var.zone.subdomain, var.zone.root)

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "backend"
    location = "multiregion"
  }
}

module "backend-2" {
  source = "github.com/wiseflat/ovhcloud-infrastructure/terraform//backend"

  region     = element(tolist(var.regions), 2)
  lan_net    = module.network-region-2.lan_net
  lan_subnet = module.network-region-2.lan_subnet
  gateway    = cidrhost(element(tolist(var.frontends.lan_net), 2), 1)

  name     = var.name
  hostname = var.backends.hostname
  zone     = var.zone

  nbinstances    = var.backends.nbinstances
  keypair        = element(tolist(module.region.keypair), 2)
  image_name     = var.backends.image
  flavor_name    = var.backends.flavor
  ssh_public_key = file(var.ssh_public_key)
  disk           = var.backends.disk
  disk_size      = var.backends.disk_size

  frontend_hostname = format("%s%s.%s.%s.%s.%s", var.frontends.hostname, 1, lower(element(tolist(var.regions), 2)), var.name, var.zone.subdomain, var.zone.root)

  working_dir   = var.working_dir
  playbook_path = var.playbook_path

  metadata = {
    role     = "backend"
    location = "multiregion"
  }
}
