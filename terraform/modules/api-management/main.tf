resource "azurerm_api_management" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  virtual_network_type = "External"

  virtual_network_configuration {
    subnet_id = var.integration_subnet_id
  }

  # The inbound Gateway Private Endpoint is created by the private-endpoint
  # module. Public access is disabled only after the private path is validated.
  public_network_access_enabled = var.public_network_access_enabled

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# APIs, operations and policies belong to the API/application delivery layer.
# They can be added as separate resources once the backend contract is known.

