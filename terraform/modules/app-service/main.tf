resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  for_each = var.apps

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  https_only                                     = true
  public_network_access_enabled                  = false
  virtual_network_subnet_id                      = var.integration_subnet_id
  vnet_image_pull_enabled                        = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type         = "UserAssigned"
    identity_ids = [each.value.identity_id]
  }

  site_config {
    always_on           = true
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    health_check_path   = each.value.health_check_path

    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = each.value.identity_client_id

    application_stack {
      docker_registry_url = var.container_registry_url
      docker_image_name   = each.value.image_name
    }
  }

  app_settings = each.value.app_settings
  tags         = var.tags
}

# Private Endpoints and data-plane role assignments are intentionally composed
# outside this module. This keeps compute, network attachment and authorization
# as separate reviewable concerns.
