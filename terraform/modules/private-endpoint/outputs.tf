output "ids" {
  description = "Private Endpoint resource IDs keyed by logical service name."
  value       = { for name, endpoint in azurerm_private_endpoint.this : name => endpoint.id }
}

output "network_interface_ids" {
  description = "Private Endpoint NIC IDs keyed by logical service name."
  value       = { for name, endpoint in azurerm_private_endpoint.this : name => endpoint.network_interface[0].id }
}

output "private_ip_addresses" {
  description = "Private IP addresses keyed by logical service name for destination-specific NSG rules."
  value       = { for name, endpoint in azurerm_private_endpoint.this : name => endpoint.private_service_connection[0].private_ip_address }
}
