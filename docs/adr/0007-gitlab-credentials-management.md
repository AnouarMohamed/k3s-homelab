# ADR 0007: GitLab Credentials Management for Argo CD

## Status
Accepted

## Context
We need to securely manage GitLab credentials (deploy token) for Argo CD to access the GitLab repository. The credentials must be stored securely in the cluster and referenced by Argo CD. We evaluated two main approaches:
1. Using `ksops` to decrypt SOPS-encrypted secrets at runtime
2. Using `helm-secrets` to manage encrypted values in Helm charts

## Decision
We chose to use **SOPS-encrypted Kubernetes Secrets** with manual decryption via `sops` CLI rather than `ksops` or `helm-secrets` for the following reasons:

### Why Not ksops?
- Requires additional installation and configuration in the cluster
- Adds complexity to the Argo CD installation process
- Requires RBAC permissions for the `ksops` webhook
- More moving parts that could fail

### Why Not helm-secrets?
- Would require managing credentials through Helm values rather than native Kubernetes Secrets
- Less flexible for non-Helm managed resources
- Adds dependency to Helm chart management
- GitLab credentials are used by the Argo CD Application resource (not Helm), so Helm secrets would be less direct

### Chosen Approach: SOPS-Encrypted Kubernetes Secrets
1. Store GitLab credentials as a SOPS-encrypted Secret manifest (`gitlab-credentials.yaml.sops`)
2. Decrypt manually with `sops` before applying to cluster (or integrate into CI/CD pipeline)
3. Argo CD references the decrypted Secret directly
4. Simple, transparent, and uses existing SOPS infrastructure already in place

## Implementation
- Created `clusters/homelab/bootstrap/argocd/gitlab-credentials.yaml.sops` with encrypted GitLab credentials
- Added the SOPS file to the Argo CD bootstrap kustomization
- The secret contains:
  - GitLab repository URL
  - Encrypted deploy token (password)
  - Username for authentication

## Consequences
### Positive
- Leverages existing SOPS infrastructure
- Simple to understand and audit
- No additional cluster dependencies
- Works with both Helm and plain Kubernetes resources
- Easy to rotate credentials by re-encrypting

### Negative
- Requires manual decryption step in CI/CD or human process
- Credentials must be decrypted before applying to cluster
- Potential for accidental commit of decrypted secrets (mitigated by .gitignore)

## Validation
- The SOPS file follows our existing `.sops.yaml` configuration
- Age encryption is used (matching cluster SOPS setup)
- File is properly gitignored via `*.sops.yaml` pattern
- Can be decrypted with `sops -d clusters/homelab/bootstrap/argocd/gitlab-credentials.yaml.sops`

## Related Documents
- ADR 0001: Record architecture decisions
- .sops.yaml: SOPS configuration
- .gitignore: Secret file exclusion patterns