variable "name" {
  description = "Name of your private network"
  type        = string
}

variable "project_id" {
  description = "The user data to provide when launching the instance"
  type        = string
  default     = null
}

variable "vlan_id" {
  description = "The ID of the VLAN of the private network to create"
  type        = number
  default     = 0
}

variable "regions" {
  description = "Regions where the network will be available (all available regions by default)"
  type        = set(string)
  default     = []
}

variable "subnets" {
  description = "List of subnet to create in the private network"
  type        = list(object({ start = string, end = string, network = string, region = optional(string), dhcp = optional(bool), no_gateway = optional(bool) }))
}

variable "dhcp" {
  description = "Enable DHCP on the network"
  type        = bool
  default     = false
}

variable "no_gateway" {
  description = "Indicate if you don't want to set a default gateway IP"
  type        = bool
  default     = false
}

locals {
  name = terraform.workspace != "default" ? "${terraform.workspace}-${var.name}" : var.name
  subnets = { for subnet in var.subnets : "${subnet.start}-${subnet.end}" => {
    "start"      = subnet.start,
    "end"        = subnet.end,
    "network"    = subnet.network,
    "region"     = subnet.region != null ? subnet.region : data.openstack_compute_availability_zones_v2.zones.region,
    "dhcp"       = subnet.dhcp != null ? subnet.dhcp : var.dhcp,
    "no_gateway" = subnet.no_gateway != null ? subnet.no_gateway : var.no_gateway
    }
  }
}