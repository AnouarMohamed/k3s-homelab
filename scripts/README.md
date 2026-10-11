# Repository scripts

Scripts provide deterministic tool installation, validation, rendering, bootstrap, and
test entry points. Every script is non-interactive unless a destructive operation
requires an explicit confirmation value.

`render-config.sh` is the common in-memory substitution boundary for Kubernetes
sources. `fetch-phase2-dependencies.sh` caches only artifacts whose upstream digest or
checksum matches the repository pin. Bootstrap scripts never run as part of validation.
