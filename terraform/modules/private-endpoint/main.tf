resource "azurerm_private_endpoint" "this" {
  for_each = var.endpoints

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${each.value.name}-connection"
    private_connection_resource_id = each.value.target_resource_id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_ids) == 0 ? [] : [1]

    content {
      name                 = "default"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  }
}

