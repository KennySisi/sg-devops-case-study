output "service_plan_id" {
  description = "Resource ID of the App Service Plan."
  value       = azurerm_service_plan.this.id
}

output "app_ids" {
  description = "App Service resource IDs keyed by logical role."
  value       = { for role, app in azurerm_linux_web_app.this : role => app.id }
}

output "default_hostnames" {
  description = "Default App Service hostnames keyed by logical role."
  value       = { for role, app in azurerm_linux_web_app.this : role => app.default_hostname }
}

