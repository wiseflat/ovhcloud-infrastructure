variable "region" {
  description = "The id of the openstack region"
  type        = string
}

variable "name" {
  description = "name of blog. Used to forge subdomain"
  type        = string
}

variable "restricted_ip" {
  description = "restricted_ip"
  type        = set(string)
  default     = []
}

variable "restricted_port" {
  description = "restricted_port"
  type        = set(number)
  default     = []
}

variable "public_port" {
  description = "public_port"
  type        = set(number)
  default     = []
}
