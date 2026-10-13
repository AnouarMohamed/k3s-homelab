# ADR 0010: Separate bootstrap and runtime secrets

## Context

Argo CD, Cloudflare access, object-storage backups, and certificate issuance must work
before OpenBao is available. Moving those credentials into OpenBao would create a
bootstrap cycle: the cluster would need the secret service that it is still trying to
install and unseal.

## Decision

I keep only bootstrap credentials in SOPS/age: the GitLab repository credential,
Cloudflare DNS and Tunnel tokens, and the three scoped S3 credentials used by Longhorn,
CloudNativePG, and Velero. They remain encrypted in Git and are re-encrypted with my
own age recipient before bootstrap.

OpenBao becomes the source for secrets introduced after the runtime-secrets layer.
External Secrets authenticates with short-lived, audience-bound Kubernetes tokens. A
namespace role can read only `secret/<namespace>/*`. Secret writes require a separately
issued, eight-hour operator token whose policy cannot change auth methods, policies, or
system configuration. Later identity work may replace this temporary human workflow
with OIDC-backed administration.

OpenBao uses manual Shamir unseal. Initialization output, unseal shares, root tokens,
operator tokens, and runtime values never enter Git, shell arguments, logs, or
Kubernetes manifests.

## Rejected alternatives

- I rejected storing every secret in SOPS because long-lived decrypted Kubernetes
  Secrets would remain the runtime source and rotation would require Git commits.
- I rejected placing bootstrap credentials in OpenBao because recovery would depend on
  the unavailable service.
- I rejected automatic unseal without a selected external KMS or HSM because inventing
  a trust service would weaken the recovery design.
- I rejected a shared static OpenBao token in a Kubernetes Secret; Kubernetes auth and
  TokenRequest provide bounded, short-lived credentials instead.

## Tradeoffs

The boundary is by design not a complete SOPS migration. Bootstrap credentials
still need disciplined age-key custody and periodic rotation. After a total power loss,
an operator must unseal enough Raft members before runtime secrets can refresh. Existing
Kubernetes Secrets can keep workloads running during a short OpenBao outage, so their
rotation and deletion must be managed deliberately.
