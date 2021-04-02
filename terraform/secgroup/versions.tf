terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.35.0"
    }
  }
  required_version = ">= 0.14"
}
