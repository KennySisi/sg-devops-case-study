variable "resource_group_name" {
  description = "Resource group containing the App Service resources."
  type        = string
}

variable "location" {
  description = "Azure region for App Service."
  type        = string
}

variable "service_plan_name" {
  description = "Linux App Service Plan name."
  type        = string
}

variable "sku_name" {
  description = "App Service Plan SKU."
  type        = string
  default     = "P1v3"
}

variable "integration_subnet_id" {
  description = "Delegated subnet shared by the two App Services for outbound VNet Integration."
  type        = string
}

variable "container_registry_url" {
  description = "HTTPS URL of the private Azure Container Registry."
  type        = string
}

variable "apps" {
  description = "Frontend and Backend application definitions keyed by logical role."
  type = map(object({
    name               = string
    identity_id        = string
    identity_client_id = string
    image_name         = string
    health_check_path  = optional(string, "/health")
    app_settings       = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for role in keys(var.apps) : contains(["frontend", "backend"], role)])
    error_message = "Application keys must be frontend and/or backend."
  }
}

variable "tags" {
  description = "Mandatory enterprise tags."
  type        = map(string)
  default     = {}
}

