# Terraform Scaffold

This directory is a representative Infrastructure as Code scaffold for the case study. It demonstrates the intended module contracts, environment composition, provider separation and security defaults without attempting to implement every Azure service.

Implemented example modules:

- `network`: spoke VNet, subnets, delegation, NSGs and associations.
- `app-service`: one Linux App Service Plan with Frontend and Backend Web Apps, Managed Identity and VNet Integration.
- `api-management`: APIM Standard v2 with outbound VNet Integration.
- `private-endpoint`: reusable Private Endpoint and Private DNS zone-group creation.

Application Gateway, data services, Azure AI Foundry, Azure Machine Learning, ACR and detailed RBAC modules would follow the same `main.tf`, `variables.tf`, `outputs.tf` contract. They are intentionally omitted to keep this submission lightweight.

## Design conventions

- Provider and backend configuration live in the environment root, not in child modules.
- Modules accept resource IDs rather than looking up shared resources implicitly.
- Environment state, identities and configuration are separated.
- Shared connectivity resources use an aliased provider when Terraform is authorised to manage them.
- Secrets are not accepted through ordinary variables or committed tfvars files.
- Resource names and mandatory tags are passed from the environment layer.
- Public data-plane access is disabled only after Private Endpoint and DNS dependencies are in place.

## Example structure

```text
terraform/
├── modules/
│   ├── network/
│   ├── app-service/
│   ├── api-management/
│   └── private-endpoint/
└── environments/
    ├── dev/
    ├── uat/
    └── prod/
```

The files are intentionally not applied as part of this case-study submission. A real implementation would pin the generated provider lock file, run validation/security checks in CI and use a private remote state backend.

