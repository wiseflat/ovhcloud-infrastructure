terraform {
  source = "../../infra//monoregion"
}

locals {
  project = yamldecode(file(find_in_parent_folders("terragrunt.yml")))
  vlan_id = 1

  nbinstances = {
    frontends = 0
    backends  = 0
  }
}

inputs = {
  restricted_ip   = local.project.restricted_ip
  restricted_port = local.project.restricted_port

  zone = local.project.zone

  vlan_id  = local.vlan_id
  # vrack_id = local.project.vrack_id

  # name = "monoregion"

  # regions = [
  #   "UK1"
  # ]

  domains = local.project.domains

  frontends = {
    lan_net = [
      "10.0.1.0/24"
    ]
    vrack_net   = "192.168.0.0/16"
    hostname    = "frontend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = local.nbinstances.frontends
    disk        = false
    disk_size   = 10
    ansible     = false
  }

  backends = {
    hostname    = "backend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = local.nbinstances.backends
    disk        = false
    disk_size   = 10
    ansible     = false
  }

  working_dir    = local.project.working_dir
  ssh_public_key = local.project.ssh_public_key
  playbook_path  = local.project.playbook_path
}
