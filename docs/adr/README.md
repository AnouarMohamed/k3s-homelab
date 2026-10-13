# Architecture Decision Records

This directory contains sequential architecture decisions. Current decisions cover
k3s, Cilium, Argo CD, Cloudflare access, Cilium WireGuard encryption, and the
SOPS/KSOPS bootstrap boundary, Cloudflare/OpenTofu state handling, layered storage and
backup, the boundary between bootstrap and runtime secrets, and the bounded telemetry
stack, plus staged application admission policy. Phase 12 adds the final indexed
decision map and verifies links.

- [ADR 0010: Separate bootstrap and runtime secrets](0010-bootstrap-and-runtime-secrets.md)
- [ADR 0011: Use a bounded LGTM observability stack](0011-bounded-observability-stack.md)
- [ADR 0012: Audit application policy before denial](0012-audit-before-policy-denial.md)
- [ADR 0013: Promote digests and mirror release packages to GHCR](0013-digest-promotion-and-ghcr-mirroring.md)
