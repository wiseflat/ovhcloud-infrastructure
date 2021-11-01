variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "vrack-Net"
}

variable "project_id" {
  description = "Public cloud project id"
  type        = string
}

variable "regions" {
  description = "Regions"
  type        = list(any)
  default     = []
}

variable "vlan_id" {
  description = "Vlan id"
  type        = number
}

variable "cloud_project" {
  description = "cloud project"
}
