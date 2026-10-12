# Architecture Decision Records

This directory contains sequential architecture decisions. Current decisions cover
k3s, Cilium, Argo CD, Cloudflare access, Cilium WireGuard encryption, and the
SOPS/KSOPS bootstrap boundary, Cloudflare/OpenTofu state handling, layered storage and
backup, and the boundary between bootstrap and runtime secrets. Phase 12 adds the final
indexed decision map and verifies links.

- [ADR 0010: Separate bootstrap and runtime secrets](0010-bootstrap-and-runtime-secrets.md)
