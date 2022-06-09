# tf-net-vrack-ovh

This terraform module allow you to create an OVH private network on their internal [vRack](https://www.ovh.com/world/solutions/vrack/) solution.

It was design to work alongside [OVH VM module](https://github.com/reneca/tf-vm-ovh), if an OVH VM need a private network.

## Providers to enable

Providers to enable are defined in the [OVH documentation](https://docs.ovh.com/us/en/public-cloud/how-to-use-terraform/):

```hcl
# Define providers and set versions
terraform {
required_version    = ">= 0.14.0" # Takes into account Terraform versions from 0.14.0
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

# Configure the OpenStack provider hosted by OVHcloud
provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3/" # Authentication URL
  domain_name = "default" # Domain name - Always at 'default' for OVHcloud
  alias       = "ovh" # An alias
}

provider "ovh" {
  alias              = "ovh"
  endpoint           = "ovh-eu"
  application_key    = "<your_access_key>"
  application_secret = "<your_application_secret>"
  consumer_key       = "<your_consumer_key>"
}
```

## APIs to enable

| Name | Url |
|------|-----|
| OVH domain name | [OVH token generation page](https://www.ovh.com/auth/api/createToken?GET=/*&POST=/*&PUT=/*&DELETE=/*) |
| Openstack compute | [OpenRC file](https://docs.ovh.com/us/en/public-cloud/set-openstack-environment-variables/) |

# Sample

## Simple private network

The network will be deploy in your default zone

```hcl
module "net-vrack" {
  source = "git::https://github.com/reneca/tf-net-vrack-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name = "private_net"
  subnets = [
    {
      start   = "192.168.168.1"
      end     = "192.168.168.250"
      network = "192.168.168.0/24"
    }
  ]
}
```

## Private network with custom configuration

If the project ID is unknown from the OVH provider, it can be specified by project_id which was the _OS_TENANT_ID_.

By default the _vlan_id_ is 0, but it can be change.

The subnet list can also have _region_, _dhcp_, and _no_gateway_ option.

```hcl
module "net-vrack" {
  source = "git::https://github.com/reneca/tf-net-vrack-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  project_id = "OS_TENANT_ID"
  name       = "private_net"
  vlan_id    = 100
  subnets = [
    {
      start      = "192.168.168.1"
      end        = "192.168.168.250"
      network    = "192.168.168.0/24"
      region     = "BHS5"
      dhcp       = true
      no_gateway = false
    }
  ]
}
```

## Multiple region private network

Here is how you deploy a private network accros multiple regions (EU region in the example).

To not have to define _dhcp_, and _no_gateway_ option every time on subnets, they can be provide directly on the module.

```hcl
variable "net_prefix" {
  default = "10.100"
}

data "ovh_cloud_project_regions" "regions" {
  has_services_up = ["network"]
}

data "ovh_cloud_project_region" "region" {
  for_each = data.ovh_cloud_project_regions.regions.names
  name     = each.value
}

locals {
  subnets = [for k, v in data.ovh_cloud_project_region.region :
    {
      "start"   = "${var.net_prefix}.${index(keys(data.ovh_cloud_project_region.region), k)}.1"
      "end"     = "${var.net_prefix}.${index(keys(data.ovh_cloud_project_region.region), k)}.250"
      "network" = "${var.net_prefix}.0.0/16"
      "region"  = "${k}"
    }
    # Comment the next line to deploy on all region (not only Europe)
    if v.continent_code == "EU"
  ]
  regions = [for subnet in local.subnets : subnet.region]
}

module "net-vrack" {
  source = "git::https://github.com/reneca/tf-net-vrack-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name       = "private_net"
  vlan_id    = 100
  regions    = local.regions
  dhcp       = true
  no_gateway = false
  subnets    = local.subnets
}
```

# Module specifications

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.0 |
| <a name="requirement_openstack"></a> [openstack](#requirement\_openstack) | ~> 1.42.0 |
| <a name="requirement_ovh"></a> [ovh](#requirement\_ovh) | >= 0.13.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_openstack"></a> [openstack](#provider\_openstack) | ~> 1.42.0 |
| <a name="provider_ovh"></a> [ovh](#provider\_ovh) | >= 0.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [ovh_cloud_project_network_private.network](https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_network_private) | resource |
| [ovh_cloud_project_network_private_subnet.subnet](https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_network_private_subnet) | resource |
| [openstack_compute_availability_zones_v2.zones](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/compute_availability_zones_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dhcp"></a> [dhcp](#input\_dhcp) | Enable DHCP on the network | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of your private network | `string` | n/a | yes |
| <a name="input_no_gateway"></a> [no\_gateway](#input\_no\_gateway) | Indicate if you don't want to set a default gateway IP | `bool` | `false` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The user data to provide when launching the instance | `string` | `null` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Regions where the network will be available (all available regions by default) | `set(string)` | `[]` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet to create in the private network | `list(object({ start = string, end = string, network = string, region = optional(string), dhcp = optional(bool), no_gateway = optional(bool) }))` | n/a | yes |
| <a name="input_vlan_id"></a> [vlan\_id](#input\_vlan\_id) | The ID of the VLAN of the private network to create | `number` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_net_name"></a> [net\_name](#output\_net\_name) | Name of the created private network |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | List of created subnets on the private network |
