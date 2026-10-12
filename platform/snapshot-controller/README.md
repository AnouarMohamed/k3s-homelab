# CSI snapshot controller

K3s does not guarantee this cluster-scoped controller, so Phase 5 vendors the five
checksum-verified upstream `v8.6.0` manifests and layers a digest pin, probes, resource
budgets, security context, standard labels, and NetworkPolicy through Kustomize. It
enables the GA per-volume snapshot API used by Longhorn and Velero; group snapshots are
not enabled.

Operate through the `snapshot-controller` Argo CD Application. Validate the upstream
checksums and rendered policy with `make validate-storage`; verify controller leadership
and a real snapshot only through the hardware ledger.
