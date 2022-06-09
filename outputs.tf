output "net_name" {
  description = "Name of the created private network"
  value       = ovh_cloud_project_network_private.network.name
}

output "subnets" {
  description = "List of created subnets on the private network"
  value       = ovh_cloud_project_network_private_subnet.subnet
}