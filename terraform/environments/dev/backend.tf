terraform {
  # Values are supplied from backend.hcl at runtime. Credentials are provided
  # by the GitHub OIDC identity and are never stored in this repository.
  backend "azurerm" {}
}
