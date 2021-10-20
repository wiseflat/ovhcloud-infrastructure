terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "0.15.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.44.0"
    }
  }
  required_version = ">= 1.0.8"
}
