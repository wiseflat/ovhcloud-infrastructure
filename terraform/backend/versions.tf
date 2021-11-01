terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.44.0"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}
