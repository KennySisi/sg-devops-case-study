locals {
  name_suffix = "${var.workload_name}-${var.environment}-aue"

  tags = merge(var.tags, {
    environment = var.environment
    workload    = var.workload_name
    managed-by  = "terraform"
  })

  subnets = {
    "snet-appgw" = {
      address_prefixes = ["10.60.0.0/24"]
      nsg_name         = "nsg-${local.name_suffix}-appgw"
    }
    "snet-apim-integration" = {
      address_prefixes   = ["10.60.1.0/27"]
      nsg_name           = "nsg-${local.name_suffix}-apim"
      service_delegation = "Microsoft.Web/serverFarms"
    }
    "snet-appsvc-integration" = {
      address_prefixes   = ["10.60.2.0/26"]
      nsg_name           = "nsg-${local.name_suffix}-appsvc"
      service_delegation = "Microsoft.Web/serverFarms"
    }
    "snet-private-endpoints" = {
      address_prefixes                  = ["10.60.3.0/24"]
      nsg_name                          = "nsg-${local.name_suffix}-pe"
      private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
    }
  }
}

resource "azurerm_resource_group" "network" {
  name     = "rg-${local.name_suffix}-network"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "application" {
  name     = "rg-${local.name_suffix}-application"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"

  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  vnet_name           = "vnet-${local.name_suffix}-001"
  address_space       = var.vnet_address_space
  subnets             = local.subnets
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "app" {
  for_each = toset(["frontend", "backend"])

  name                = "uai-${local.name_suffix}-${each.key}"
  resource_group_name = azurerm_resource_group.application.name
  location            = var.location
  tags                = local.tags
}

module "app_service" {
  source = "../../modules/app-service"

  resource_group_name    = azurerm_resource_group.application.name
  location               = var.location
  service_plan_name      = "asp-${local.name_suffix}-001"
  integration_subnet_id  = module.network.subnet_ids["snet-appsvc-integration"]
  container_registry_url = var.container_registry_url

  apps = {
    frontend = {
      name               = "app-${local.name_suffix}-web-${var.unique_suffix}"
      identity_id        = azurerm_user_assigned_identity.app["frontend"].id
      identity_client_id = azurerm_user_assigned_identity.app["frontend"].client_id
      image_name         = var.frontend_image
      health_check_path  = "/health"
    }
    backend = {
      name               = "app-${local.name_suffix}-api-${var.unique_suffix}"
      identity_id        = azurerm_user_assigned_identity.app["backend"].id
      identity_client_id = azurerm_user_assigned_identity.app["backend"].client_id
      image_name         = var.backend_image
      health_check_path  = "/health"
    }
  }

  tags = local.tags
}

# Both apps need image-pull access. Only the Backend identity receives separate
# Data, Key Vault and AI data-plane permissions in the complete implementation.
resource "azurerm_role_assignment" "app_acr_pull" {
  for_each = azurerm_user_assigned_identity.app

  scope                = var.container_registry_id
  role_definition_name = var.acr_pull_role_name
  principal_id         = each.value.principal_id
}

module "api_management" {
  source = "../../modules/api-management"

  name                  = "apim-${local.name_suffix}-${var.unique_suffix}"
  resource_group_name   = azurerm_resource_group.application.name
  location              = var.location
  publisher_name        = var.apim_publisher_name
  publisher_email       = var.apim_publisher_email
  integration_subnet_id = module.network.subnet_ids["snet-apim-integration"]

  # Final state. A staged deployment may temporarily enable public access until
  # the Gateway PE and private DNS path have been verified.
  public_network_access_enabled = false
  tags                          = local.tags
}

module "private_endpoints" {
  source = "../../modules/private-endpoint"

  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["snet-private-endpoints"]

  endpoints = {
    frontend = {
      name                 = "pe-${local.name_suffix}-frontend"
      target_resource_id   = module.app_service.app_ids["frontend"]
      subresource_names    = ["sites"]
      private_dns_zone_ids = [var.private_dns_zone_ids.azurewebsites]
    }
    backend = {
      name                 = "pe-${local.name_suffix}-backend"
      target_resource_id   = module.app_service.app_ids["backend"]
      subresource_names    = ["sites"]
      private_dns_zone_ids = [var.private_dns_zone_ids.azurewebsites]
    }
    apim_gateway = {
      name                 = "pe-${local.name_suffix}-apim-gateway"
      target_resource_id   = module.api_management.id
      subresource_names    = ["Gateway"]
      private_dns_zone_ids = [var.private_dns_zone_ids.azure_api]
    }
  }

  tags = local.tags
}

# Enabling NSG policies on the PE subnet makes these destination-specific rules
# effective for traffic addressed to the Private Endpoint NICs.
locals {
  pe_inbound_rules = {
    appgw_to_frontend = {
      priority                 = 100
      source_subnet            = "snet-appgw"
      destination_endpoint_key = "frontend"
    }
    appgw_to_apim = {
      priority                 = 110
      source_subnet            = "snet-appgw"
      destination_endpoint_key = "apim_gateway"
    }
    apim_to_backend = {
      priority                 = 120
      source_subnet            = "snet-apim-integration"
      destination_endpoint_key = "backend"
    }
  }
}

resource "azurerm_network_security_rule" "pe_inbound_allow" {
  for_each = local.pe_inbound_rules

  name                        = "Allow-${each.key}"
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = local.subnets[each.value.source_subnet].address_prefixes[0]
  destination_address_prefix  = module.private_endpoints.private_ip_addresses[each.value.destination_endpoint_key]
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = module.network.nsg_names["snet-private-endpoints"]
}

resource "azurerm_network_security_rule" "pe_inbound_deny_other_vnet" {
  name                        = "Deny-Other-VNet-To-Private-Endpoints"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = module.network.nsg_names["snet-private-endpoints"]
}

# Intentionally omitted from this lightweight scaffold:
# - Hub peering and central DNS zone lifecycle, which are Landing Zone owned.
# - Application Gateway, ACR, Storage, Cosmos DB, Key Vault, Foundry and ML.
# - Their PE entries, destination-specific NSG rules and Backend RBAC bindings.
# - APIM APIs/policies and application release configuration.
