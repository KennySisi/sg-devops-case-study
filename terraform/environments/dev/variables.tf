variable "workload_subscription_id" {
  description = "Subscription containing the Development workload spoke."
  type        = string
}

variable "connectivity_subscription_id" {
  description = "Landing Zone connectivity subscription containing shared DNS."
  type        = string
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "australiaeast"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "This environment root is reserved for Development."
  }
}

variable "workload_name" {
  description = "Short workload identifier used in resource names."
  type        = string
  default     = "aip"
}

variable "unique_suffix" {
  description = "Short suffix used for globally unique resource names."
  type        = string
}

variable "vnet_address_space" {
  description = "Development spoke address space allocated by enterprise IPAM."
  type        = list(string)
  default     = ["10.60.0.0/16"]
}

variable "container_registry_id" {
  description = "Resource ID of the private ACR used by both applications."
  type        = string
}

variable "container_registry_url" {
  description = "ACR login server including the https scheme."
  type        = string
}

variable "frontend_image" {
  description = "Immutable frontend image name and tag or digest."
  type        = string
}

variable "backend_image" {
  description = "Immutable backend image name and tag or digest."
  type        = string
}

variable "acr_pull_role_name" {
  description = "ACR pull role selected for the registry's RBAC or ABAC permission mode."
  type        = string
  default     = "AcrPull"
}

variable "private_dns_zone_ids" {
  description = "IDs of centrally managed Private DNS Zones supplied by the Landing Zone."
  type = object({
    azurewebsites = string
    azure_api     = string
  })
}

variable "apim_publisher_name" {
  description = "APIM publisher display name."
  type        = string
}

variable "apim_publisher_email" {
  description = "APIM publisher contact email."
  type        = string
}

variable "tags" {
  description = "Additional environment tags merged with mandatory tags."
  type        = map(string)
  default     = {}
}
