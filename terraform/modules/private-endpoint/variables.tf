variable "resource_group_name" {
  description = "Resource group containing the workload Private Endpoints."
  type        = string
}

variable "location" {
  description = "Azure region for Private Endpoint NICs."
  type        = string
}

variable "subnet_id" {
  description = "Dedicated workload Private Endpoint subnet ID."
  type        = string
}

variable "endpoints" {
  description = "Private Endpoint definitions keyed by logical service name."
  type = map(object({
    name                 = string
    target_resource_id   = string
    subresource_names    = list(string)
    private_dns_zone_ids = list(string)
  }))

  validation {
    condition     = alltrue([for endpoint in values(var.endpoints) : length(endpoint.subresource_names) > 0])
    error_message = "Every Private Endpoint must specify at least one subresource name."
  }
}

variable "tags" {
  description = "Mandatory enterprise tags."
  type        = map(string)
  default     = {}
}

