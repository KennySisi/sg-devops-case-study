# UAT Environment

UAT reuses the same versioned modules and composition pattern as Development, with its own spoke CIDR, names, identities, GitHub Environment approval, variables and remote-state key.

The complete root configuration is intentionally not duplicated in this lightweight scaffold. In a production repository, shared composition can be promoted through versioned modules or a thin stack wrapper while keeping UAT state and permissions isolated.
