# Platform Components

Argo CD installs the networking, edge, storage, secret, identity, delivery, and
resilience controllers from this directory. Each component owns a pinned dependency
file, configuration, operational README, and purpose-named resources where applicable.

Use the phase-specific `make validate-*` target before changing a component. Runtime
operations and recovery procedures are indexed in [`docs/runbooks`](../docs/runbooks/README.md).
