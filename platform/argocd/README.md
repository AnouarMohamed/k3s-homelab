# Argo CD

Argo CD `v3.5.4` is installed from chart `10.10.2` and manages this repository from
GitLab at revision `main`. The chart digest and all config-management sidecar images
are immutable pins in `dependencies.env`.

The `homelab-renderer-v1` sidecar renders only known repository paths through
`scripts/render-gitops.sh`. It supplies pinned yq, Kustomize, and KSOPS binaries,
mounts the age identity read-only, and uses its own temporary volume. It never writes
rendered private addresses or decrypted secrets into Git.

The server remains a ClusterIP with no Ingress, HTTPRoute, or public tunnel. Follow
the recovery runbook for local port-forward access and the built-in `admin`
break-glass account. Run `make validate-gitops` offline and `make bootstrap-gitops`
only from the trusted administration host.
