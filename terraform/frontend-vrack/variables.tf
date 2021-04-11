# secgroup

variable "secgroup" {
  description = "Security group"
}

# network

variable "region" {
  description = "Region of your instance"
}

variable "ext_net" {
  description = "External network"
}

variable "lan_net" {
  description = "Private network"
}

variable "lan_subnet" {
  description = "Private subnet"
}

variable "public_subnet" {
  description = "Cidr"
  type        = string
}

## Vrack

variable "vrack_net" {
  description = "Multi region private network"
}

variable "vrack_subnet" {
  description = "Multi region private subnet"
}

variable "vrack_fixed_ip" {
  description = "Fixed ip of the vrack interface"
}

# Disk

variable "disk" {
  description = "Additional disk"
  type        = bool
  default     = false
}

variable "disk_size" {
  description = "Additional disk size"
  type        = number
  default     = 10
}

# Instance

variable "nbinstances" {
  description = "Number of instances to deploy"
  default     = 0
  type        = number
}

variable "name" {
  description = "Name of your infrastructure"
}

variable "hostname" {
  description = "Server Hostname (without digit)"
  default     = "frontend-vrack"
}

variable "zone" {
  description = "Dns zone"
  type = object({
    root      = string
    subdomain = string
  })
}

variable "flavor_name" {
  description = "Flavor name of your instance"
  default     = "s1-2"
}

variable "image_name" {
  description = "Image name of your instance"
  default     = "Ubuntu 20.04"
}

variable "keypair" {
  description = "Keypair of the openstack instance"
}

variable "ssh_public_key" {
  description = "ssh public key used by cloudinit"
}

variable "metadata" {
  description = "A map of metadata to add to all resources supporting it."
}


# Operations

variable "playbook_path" {
  description = "Path of Ansible playbooks"
}

variable "working_dir" {
  description = "Path of your environment"
}
