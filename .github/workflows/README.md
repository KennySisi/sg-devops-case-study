# GitHub Actions Scaffold

These workflows demonstrate the CI/CD boundaries described by the case study. They are intentionally not connected to a live Azure tenant.

Only the Development Terraform root is represented in this lightweight repository. The UAT and Production workflow choices show the promotion contract, but their environment roots must be completed before those jobs can run.

## Workflows

- `infrastructure.yml`: hosted-runner formatting, validation and IaC scanning; manually selected plan/apply jobs run on an Azure-connected private runner and authenticate through OIDC.
- `application-release.yml`: sample application contract for unit testing, container build, vulnerability scanning, private ACR push, App Service image update and private smoke testing.

The release workflow is manual because this repository does not contain application source. A future application repository is expected to provide:

```text
src/
├── frontend/
│   ├── Dockerfile
│   └── test.sh
└── backend/
    ├── Dockerfile
    └── test.sh
```

For simplicity, the sample keeps build, scan, publish and deployment in one private-runner job. A mature application pipeline can keep unit tests and builds on hosted runners, then transfer reviewed immutable artifacts to a private publish job if the organisation accepts that artifact boundary.

## Required GitHub configuration

Create protected GitHub Environments named `dev`, `uat` and `prod`. Production should require reviewers and restrict deployment branches.

Environment variables used by the infrastructure workflow include:

- Azure/OIDC: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `CONNECTIVITY_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID_TERRAFORM_PLAN`, `AZURE_CLIENT_ID_TERRAFORM_APPLY`.
- Terraform: `TF_ROOT`, `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, `TFSTATE_CONTAINER`.
- Workload values: `UNIQUE_SUFFIX`, `CONTAINER_REGISTRY_ID`, `CONTAINER_REGISTRY_URL`, `FRONTEND_IMAGE`, `BACKEND_IMAGE`, `PRIVATE_DNS_ZONE_IDS_JSON`, `APIM_PUBLISHER_NAME`, `APIM_PUBLISHER_EMAIL`.

Environment variables used by the release workflow include:

- OIDC: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID_RELEASE`.
- Deployment: `ACR_NAME`, `ACR_LOGIN_SERVER`, `APP_RESOURCE_GROUP`, `FRONTEND_APP_NAME`, `BACKEND_APP_NAME`, `INTERNAL_APP_FQDN`.

The corresponding Entra applications or user-assigned identities require federated credentials scoped to this repository and GitHub Environment. No client secret is stored in GitHub.

## Private runner boundary

The runner group used by plan, apply and release jobs must provide labels `self-hosted`, `linux`, `x64` and `azure-private`. It needs:

- private DNS and network reachability to the Terraform state account, ACR and internal Application Gateway;
- Terraform, Docker, Azure CLI and a current GitHub Actions runner runtime;
- controlled outbound access to GitHub and required package registries; and
- access restricted to trusted workflows and users.

Pull requests never run on the private runner. Before Production use, third-party actions should be pinned to reviewed immutable commit SHAs in accordance with organisation policy.
