# Repository scripts

Scripts provide deterministic tool installation, validation, rendering, bootstrap, and
test entry points. Every script is non-interactive unless a destructive operation
requires an specific confirmation value.

`render-config.sh` is the common in-memory substitution boundary for Kubernetes
sources. `fetch-cilium-dependencies.sh` caches only artifacts whose upstream digest or
checksum matches the repository pin. `render-gitops.sh` is the allowlisted Argo CD CMP
entry point, while `fetch-argocd-dependencies.sh` and `validate-gitops.sh` verify the
Argo CD chart and restricted application tree. Bootstrap scripts never run as part of
validation.
