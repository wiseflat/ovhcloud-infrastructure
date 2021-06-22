variable "regions" {
  description = "The id of the openstack region"
  type        = set(string)
  default = [
    "DE1",
    "UK1",
    "GRA5"
  ]
}

variable "name" {
  description = "Name of your infrastructure"
  default     = "multiregion"
}

variable "project_id" {
  description = "id of the openstack project"
}

variable "ssh_public_key" {
  description = "The path of the ssh public key that will be used"
}

variable "vlan_id" {
  description = "vlan id"
}

variable "vrack_id" {
  description = "vrack id"
}

variable "playbook_path" {
  description = "Path of Ansible playbooks"
}

variable "network_name" {
  description = "Local network name between instances"
  type        = string
  default     = "Int-Net"
}

variable "working_dir" {
  description = "Path of Ansible playbooks"
}

variable "restricted_ip" {
  description = "restricted_ip"
  type        = set(string)
  default     = []
}

variable "restricted_port" {
  description = "restricted_port"
  type        = set(number)
  default = [
    22
  ]
}

variable "public_port" {
  description = "public_port"
  type        = set(number)
  default = [
    80,
    443
  ]
}

variable "zone" {
  description = "Dns zone"
  type = object({
    root      = string
    subdomain = string
    region    = string
  })
}

variable "domains" {
  description = "id of the openstack project"
  type = list(object({
    zone      = string
    subdomain = string
    target    = string
    fieldtype = string
    ttl       = number
  }))
  default = []
}

variable "nbinstances_region0" {
  description = "Number of instances to deploy"
  type = object({
    backends  = number
    frontends = number
  })
  default = {
    backends  = 0
    frontends = 0
  }
}

variable "nbinstances_region1" {
  description = "Number of instances to deploy"
  type = object({
    backends  = number
    frontends = number
  })
  default = {
    backends  = 0
    frontends = 0
  }
}

variable "nbinstances_region2" {
  description = "Number of instances to deploy"
  type = object({
    backends  = number
    frontends = number
  })
  default = {
    backends  = 0
    frontends = 0
  }
}

variable "frontends" {
  description = "Frontend definition"
  type = object({
    lan_net     = set(string)
    vrack_net   = string
    hostname    = string
    flavor      = string
    image       = string
    disk        = bool
    disk_size   = number
    ansible     = bool
  })
  default = {
    lan_net = [
      "10.0.1.0/24",
      "10.0.2.0/24",
      "10.0.3.0/24"
    ]
    vrack_net   = "192.168.0.0/16"
    hostname    = "frontend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    disk        = false
    disk_size   = 10
    ansible     = false
  }
}

variable "backends" {
  description = "Backends definition"
  type = object({
    hostname    = string
    flavor      = string
    image       = string
    disk        = bool
    disk_size   = number
    ansible     = bool
  })
  default = {
    hostname    = "backend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    disk        = false
    disk_size   = 10
    ansible     = false
  }
}
