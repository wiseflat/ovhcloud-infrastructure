terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "0.11.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.35.0"
    }
  }
  required_version = ">= 0.13"
}
