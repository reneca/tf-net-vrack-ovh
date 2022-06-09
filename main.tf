# Providers versions
terraform {
  required_version = ">= 0.14.0"                      # Terraform version from 0.14.0 to allow optionnal type
  experiments      = [module_variable_optional_attrs] # Allow optionnal for type
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.42.0"
    }

    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.13.0"
    }
  }
}

# Get the compute region info to deploy
data "openstack_compute_availability_zones_v2" "zones" {}

# Create the private network
resource "ovh_cloud_project_network_private" "network" {
  service_name = var.project_id
  name         = local.name
  regions      = var.regions
  vlan_id      = var.vlan_id
}

# Create all subnetworks from the created private network
resource "ovh_cloud_project_network_private_subnet" "subnet" {
  for_each     = local.subnets
  service_name = var.project_id
  network_id   = ovh_cloud_project_network_private.network.id
  start        = each.value.start
  end          = each.value.end
  network      = each.value.network
  region       = each.value.region
  dhcp         = each.value.dhcp
  no_gateway   = each.value.no_gateway
}