# Choose Argo CD over Flux

## Status

Accepted

## Context

The platform needs continuous reconciliation from GitLab, a clear dependency order,
restricted tenancy boundaries, OIDC integration, and a useful operational view for a
portfolio demonstration.

## Decision

Use the pinned Argo CD Helm chart, bootstrap it once, and then let Argo CD manage the
same release. A root Application owns explicit platform Applications and a constrained
Git-directory ApplicationSet owns application entries. AppProjects use exact GitLab
sources, namespaces, and resource allowlists; generated applications cannot choose
their own project.

A pinned config-management sidecar renders central configuration in memory with `yq`,
Kustomize, and KSOPS. GitLab `main` is the deployment branch. The UI stays private.

## Consequences

- Bootstrap and disaster recovery require a documented non-GitOps entry path.
- Argo CD and ApplicationSet controllers are administrative trust boundaries.
- Read-only, administrator, OIDC, and local break-glass access must be tested without
  publishing credentials.
- Flux-specific APIs and workflows are out of scope.
