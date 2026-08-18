provider "azurerm" {
  features {}

  subscription_id = var.workload_subscription_id
}

# Shared connectivity resources are owned by the Landing Zone. This alias is
# available only for narrowly scoped operations explicitly authorised to IaC.
provider "azurerm" {
  alias = "connectivity"

  features {}

  subscription_id = var.connectivity_subscription_id
}
