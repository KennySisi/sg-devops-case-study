variable "name" {
  description = "API Management service name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing API Management."
  type        = string
}

variable "location" {
  description = "Azure region for API Management."
  type        = string
}

variable "publisher_name" {
  description = "APIM publisher display name."
  type        = string
}

variable "publisher_email" {
  description = "APIM publisher contact email."
  type        = string
}

variable "sku_name" {
  description = "APIM SKU and capacity."
  type        = string
  default     = "StandardV2_1"
}

variable "integration_subnet_id" {
  description = "Dedicated subnet used by APIM for outbound VNet Integration."
  type        = string
}

variable "public_network_access_enabled" {
  description = "Bootstrap switch. Disable only after the Gateway PE and DNS path are validated."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Mandatory enterprise tags."
  type        = map(string)
  default     = {}
}

