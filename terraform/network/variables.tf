variable "region" {
  description = "The id of the openstack region"
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = "Mono-Net"
}

variable "ext_net" {
  description = "Default ovh public network name"
  default     = "Ext-Net"
}

variable "lan_net" {
  description = "Default ovh private network name"
}

variable "dns_nameservers" {
  type        = list(string)
  description = "The list of dns servers to be pushed by dhcp"
  default = [
    "213.186.33.99",
    "8.8.8.8"
  ]
}

variable "cloud_project" {
  description = "cloud project"
}

variable "vrack_net" {
  description = "Vrack network"
}

variable "project_id" {
  description = "Public cloud project id"
}
