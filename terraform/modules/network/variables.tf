variable "resource_group_name" {
  description = "Resource group containing the spoke network."
  type        = string
}

variable "location" {
  description = "Azure region for the network resources."
  type        = string
}

variable "vnet_name" {
  description = "Name of the spoke virtual network."
  type        = string
}

variable "address_space" {
  description = "Address spaces allocated to the spoke by enterprise IPAM."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one VNet address space must be supplied."
  }
}

variable "subnets" {
  description = "Subnet definitions keyed by subnet name."
  type = map(object({
    address_prefixes                  = list(string)
    nsg_name                          = string
    service_delegation                = optional(string)
    private_endpoint_network_policies = optional(string, "Disabled")
  }))

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : contains(
        ["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"],
        subnet.private_endpoint_network_policies
      )
    ])
    error_message = "Private Endpoint network policies must use a supported AzureRM value."
  }
}

variable "tags" {
  description = "Mandatory enterprise tags."
  type        = map(string)
  default     = {}
}

