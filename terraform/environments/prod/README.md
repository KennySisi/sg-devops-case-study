# Production Environment

Production reuses the same versioned modules and composition pattern as Development, with its own spoke CIDR, names, identities, protected GitHub Environment, variables and remote-state key.

Production changes require an approved plan and use a dedicated OIDC identity. The complete root configuration is intentionally not duplicated in this lightweight scaffold.
