terraform {
  source = "../../infra//multiregion-vrack"
}

locals {
  project = yamldecode(file(find_in_parent_folders("terragrunt.yml")))
  vlan_id = 3

  nbinstances = {
    frontends      = 0
    backends       = 0
    backends_vrack = 0
  }
}

inputs = {
  restricted_ip   = local.project.restricted_ip
  restricted_port = local.project.restricted_port

  zone = local.project.zone

  vlan_id  = local.vlan_id
  # vrack_id = local.project.vrack_id

  # name = "multivrack"

  # regions = [
  #   "DE1",
  #   "UK1",
  #   "GRA5"
  # ]

  domains = local.project.domains

  frontends = {
    lan_net = [
      "10.0.1.0/24",
      "10.0.2.0/24",
      "10.0.3.0/24"
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

  backends_vrack = {
    hostname    = "backend-vrack"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = local.nbinstances.backends_vrack
    disk        = false
    disk_size   = 10
    ansible     = false
  }

  working_dir    = local.project.working_dir
  ssh_public_key = local.project.ssh_public_key
  playbook_path  = local.project.playbook_path
}
