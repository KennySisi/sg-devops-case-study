output "id" {
  description = "Resource ID of API Management."
  value       = azurerm_api_management.this.id
}

output "gateway_url" {
  description = "Default APIM gateway URL used by Application Gateway."
  value       = azurerm_api_management.this.gateway_url
}

output "principal_id" {
  description = "System-assigned Managed Identity principal ID."
  value       = azurerm_api_management.this.identity[0].principal_id
}

