output "vnet_id" {
  description = "Development spoke VNet resource ID."
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Development subnet IDs keyed by subnet name."
  value       = module.network.subnet_ids
}

output "app_service_ids" {
  description = "Frontend and Backend App Service resource IDs."
  value       = module.app_service.app_ids
}

output "apim_gateway_url" {
  description = "APIM gateway hostname used when configuring Application Gateway."
  value       = module.api_management.gateway_url
}

output "private_endpoint_ids" {
  description = "Private Endpoint resource IDs keyed by service."
  value       = module.private_endpoints.ids
}
