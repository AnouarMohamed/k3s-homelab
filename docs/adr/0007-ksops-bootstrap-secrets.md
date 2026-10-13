# ADR 0007: Use KSOPS only for bootstrap-encrypted GitOps material

## Context

Argo CD needs repository credentials before it can synchronize the repository. Later
runtime secrets belong in OpenBao, but that service does not exist during GitOps
bootstrap. Decrypted files must never be written into this public repository or a
persistent repo-server volume.

## Decision

I use SOPS with age for bootstrap-only encrypted files and KSOPS in a pinned Argo CD
config-management sidecar. Bootstrap checks that the supplied age identity matches the
tracked public recipient, creates the age Secret directly in the cluster, decrypts the
GitLab credential through a pipe, and injects the configured repository URL in memory.

The sidecar has pinned Argo CD, KSOPS, Kustomize, and yq artifacts; a dedicated `/tmp`;
a read-only age-key mount; no service-account token requirement; and no shared temporary
directory with the main repo-server container. Its renderer accepts only approved
repository paths.

## Rejected alternatives

- Plain Kubernetes Secrets would expose credentials in Git.
- Sealed Secrets adds another bootstrap controller and key lifecycle before OpenBao.
- Helm Secrets expands the Helm execution surface and does not cover plain Kustomize
  resources as cleanly.
- Storing the age identity in Git, even encrypted with itself, would defeat the trust
  boundary.

## Tradeoff

The administration host must supply the age identity during bootstrap, and loss of that
identity requires re-encrypting bootstrap material. OpenBao replaces this mechanism for
runtime application secrets in Runtime secrets.
