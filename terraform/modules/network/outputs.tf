output "vnet_id" {
  description = "Resource ID of the spoke VNet."
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Subnet resource IDs keyed by subnet name."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "nsg_ids" {
  description = "NSG resource IDs keyed by subnet name."
  value       = { for name, nsg in azurerm_network_security_group.this : name => nsg.id }
}

output "nsg_names" {
  description = "NSG names keyed by subnet name."
  value       = { for name, nsg in azurerm_network_security_group.this : name => nsg.name }
}
