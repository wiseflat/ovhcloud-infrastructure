variable "regions" {
  description = "The id of the openstack region"
  type        = set(string)
  default = [
    "UK1"
  ]
}

variable "name" {
  description = "Name of your infrastructure"
  default     = "monoregion"
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

variable "network_name" {
  description = "Local network name between instances"
  type        = string
  default     = "Int-Net"
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


variable "format" {
  description = "Instance digit format"
  default     = "%03d"
  type        = string
}

variable "frontends" {
  description = "Frontend definition"
  type = object({
    lan_net     = set(string)
    vrack_net   = string
    hostname    = string
    flavor      = string
    image       = string
    nbinstances = number
    disk        = bool
    disk_size   = number
  })
  default = {
    lan_net = [
      "10.0.0.0/24"
    ]
    vrack_net   = "192.168.0.0/16"
    hostname    = "frontend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = 0
    disk        = false
    disk_size   = 10
  }
}

variable "backends" {
  description = "Backends definition"
  type = object({
    hostname    = string
    flavor      = string
    image       = string
    nbinstances = number
    disk        = bool
    disk_size   = number
  })
  default = {
    hostname    = "backend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = 0
    disk        = false
    disk_size   = 10
  }
}
