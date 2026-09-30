# Choose Argo CD over Flux for GitOps

## Status
Accepted

## Context
We need a GitOps tool to continuously synchronize our Kubernetes manifests from Git to the cluster. The tool should be easy to install, manage, and provide good visibility into application state. It should support the app-of-apps pattern and work well with our existing toolchain (Helm, Kustomize, etc.).

## Decision
We chose Argo CD over Flux for the following reasons:
- Argo CD provides a rich web UI for visualizing application sync status, health, and history.
- It supports multiple sources of truth (Helm, Kustomize, Jsonnet, plain manifests) and integrates well with our planned use of Kustomize and Helm.
- The app-of-apps pattern is natively supported via ApplicationSet, allowing us to manage our portfolio of applications declaratively.
- Argo CD has robust role-based access control (RBAC) and integrates with OIDC, LDAP, etc., for future authentication needs.
- It offers automated pruning of resources and supports hooks for pre/post-sync actions.
- The project is well-maintained and has a large community, aligning with our goal of using popular, well-supported tools.

## Consequences
- We will install Argo CD in its own namespace (argocd) via the official Helm chart, version pinned.
- We will configure Argo CD to use our GitLab repository as the source of truth, using SSH or token-based authentication.
- We will define an ApplicationSet in the `clusters/homelab/` directory to generate Applications for each component in platform/, observability/, policies/, apps/, etc.
- Argo CD will be responsible for ensuring the cluster state matches the Git repository.
- We will manage Argo CD itself via GitOps (bootstrapped initially, then self-managed).