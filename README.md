# Secure Azure Platform for an Internal AI Application

## Solution Overview

This repository presents a lightweight design for a secure internal employee AI application on Azure.

**Key design principles:** private-by-default connectivity, least-privilege access, and a repeatable deployment model.

Application Gateway WAF_v2 provides the private application entry point. API Management (APIM) provides API governance. Separate Azure App Services host the frontend and backend API. Storage, Cosmos DB, Key Vault, Azure Container Registry (ACR), Azure AI Foundry and Azure Machine Learning use Private Endpoints wherever supported.

Terraform defines the workload infrastructure, while GitHub Actions provides CI/CD using OIDC workload identity federation. The design focuses on workload spokes and consumes the organisation's existing Azure Landing Zone capabilities.

## Assumptions

- An Azure Landing Zone and Microsoft Entra ID already exist.
- Hub-and-spoke networking and private corporate connectivity to Azure already exist.
- Private DNS Zones are centrally managed.
- Existing Azure Policy and monitoring provide the enterprise governance baseline.
- Frontend and backend applications are packaged as container images and stored in ACR.
- Development, UAT and Production follow the same architecture pattern with separate workload resources, identities and data.

## 1. High-Level Architecture

![Azure internal AI platform architecture](diagrams/architecture.png)

**Key point:** follow the request from the employee to the application, then to the backend data and AI services.

| Flow | Path |
|---|---|
| UI traffic | Employee → Application Gateway → Frontend App Service |
| API traffic | Employee/Frontend → Application Gateway → APIM → Backend App Service |
| Backend access | Backend App Service → VNet Integration → Private Endpoints → Data / AI services |
| Deployment | GitHub Actions → OIDC → Azure; private-networked runner where private endpoint access is required |

Application Gateway provides WAF inspection and Layer 7 routing:

- UI traffic goes to the Frontend App Service through its Private Endpoint.
- API traffic goes to APIM through its Private Endpoint.
- APIM uses VNet Integration for outbound connectivity to the Backend App Service Private Endpoint.
- The Backend App Service uses VNet Integration to access approved data and AI services through their Private Endpoints.

**Design summary:** the application traffic stays on private network paths end to end.

## 2. Networking Design

Each environment uses its own spoke VNet connected to the existing enterprise hub. Address ranges are allocated through the Landing Zone / IPAM process.

### Network Segmentation

| Subnet | Purpose |
|---|---|
| Application Gateway subnet | Private application entry point and WAF |
| APIM integration subnet | APIM outbound VNet Integration |
| App Service integration subnet | App Service outbound VNet Integration |
| Private Endpoint subnet | Private Endpoints for APIM, App Services and Azure PaaS / AI services |

**Key networking distinction:**

- **Private Endpoint = private inbound access**
- **VNet Integration = outbound access into the VNet**

NSGs and routing restrict traffic to the required application paths and approved platform dependencies.

Network reachability and authorization are separate controls. A Private Endpoint makes a service privately reachable, but it does not authorize the caller.

### Private DNS

Private DNS supports Private Endpoint connectivity for workload services.

Private DNS Zones are centrally managed and linked to workload VNets where required. Applications continue to use standard Azure service FQDNs, which resolve to the corresponding Private Endpoint IP addresses.

For the internal application entry point, `ai.slatergordon.com` resolves to the private frontend IP of Application Gateway.

### Ingress and Egress

The application has no intended direct public entry point. Public network access is disabled or restricted on supported workload services after private connectivity is validated.

Required Internet-bound traffic follows the existing controlled egress path:

`Workload Spoke → Hub → Azure Firewall → Approved External Destinations`

## 3. Identity and Security

**Key point:** separate user identity, workload identity and deployment identity.

### User Identity

Employees authenticate using Microsoft Entra ID. The final employee sign-in and application authorization model is a Production design item.

### Workload Identity

Azure workloads use Managed Identities and least-privilege access.

| Identity | Main purpose |
|---|---|
| Frontend App Service MI | Pull frontend image from ACR; no direct data-service access |
| Backend App Service MI | Pull backend image and access approved Storage, Cosmos DB, Key Vault and AI services |
| Application Gateway MI | Access Key Vault certificate if required |
| APIM MI | Can be used for Production APIM-to-Backend authentication |

### Deployment Identity

GitHub Actions authenticates to Azure through OIDC workload identity federation, avoiding long-lived Azure client secrets.

Security is implemented using defence in depth:

- **Application edge:** Application Gateway WAF and APIM API controls.
- **Network:** private frontend IPs, Private Endpoints, NSGs and Hub firewall.
- **Identity:** Managed Identities and least-privilege access.
- **Secrets:** Key Vault only where secrets or certificates cannot be eliminated.
- **Governance:** existing Azure Policy and central monitoring.
- **Supply chain:** image scanning and immutable image tags / digests.

## 4. Terraform Design

**Key point:** reusable Terraform modules with environment-specific configuration.

The repository contains representative modules for:

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

Development demonstrates how the modules are composed. UAT and Production reuse the same pattern with separate configuration, Terraform state and deployment identities.

Terraform manages representative workload resources and RBAC assignments. Access to shared resources such as centrally managed Private DNS is granted only where required.

This repository is intentionally a lightweight scaffold. It demonstrates the architecture, module boundaries and deployment pattern rather than implementing every Production setting or rebuilding the existing Azure Landing Zone.

## 5. GitHub Actions CI/CD

**Key point:** infrastructure deployment and application release are separate workflows.

GitHub Actions uses OIDC federation, so no long-lived Azure client secret is stored in GitHub.

### Infrastructure Pipeline

```text
Terraform fmt / validate
→ Security checks
→ Terraform plan
→ Review
→ Manual approval for UAT / Production
→ Terraform apply
```

### Application Release Pipeline

```text
Build
→ Unit test
→ Image scan
→ Push immutable image to ACR
→ Update App Service image
→ Private smoke test
```

Jobs that need access to private ACR or internal application endpoints require Azure private network connectivity.

GitHub-hosted runners with Azure private networking are the preferred option because they reduce runner-management overhead. Self-hosted runners remain an alternative where greater infrastructure control is required.

**Remember:** OIDC solves Azure authentication; the private-networked runner solves private network connectivity.

## 6. Key Design Trade-offs

### APIM Standard v2 vs Premium v2

Standard v2 is selected because its inbound Private Endpoint and outbound VNet Integration meet the current requirements at lower cost.

**Trade-off:** Standard v2 has a more complex networking model. Premium v2 provides a more fully integrated VNet model, but at higher cost.

### Private Deployment Runner

GitHub-hosted runners with Azure private networking reduce runner-management overhead while still providing access to private ACR and internal endpoints.

**Trade-off:** GitHub-hosted runners provide less infrastructure control. Self-hosted runners provide more control but require more operational maintenance.

The final choice depends on the organisation's GitHub setup, security policy, cost and platform standards.

### Environment Isolation vs Cost

Development, UAT and Production use separate workload resources, identities and data.

**Trade-off:** stronger isolation and a smaller blast radius, at the cost of duplicated workload resources and higher cost.

## 7. Key Considerations Before Production

- Validate private DNS and end-to-end private connectivity.
- Confirm the final Azure AI Foundry / Azure Machine Learning Production configuration, including region, model availability, quota, networking and outbound requirements.
- Finalise employee sign-in and APIM-to-Backend authentication.
- The repository provides representative Terraform modules and CI/CD workflows rather than a complete Production implementation.

The design intentionally documents these dependencies rather than claiming unsupported Production completeness.
