# Threat model

## Scope and assets

This STRIDE review covers the public Git repository, GitLab pipeline and registry,
Cloudflare edge, three-node k3s cluster, runtime secrets, application data, backups,
and administrator access. The primary assets are GitOps integrity, signing identity,
OpenBao recovery material, database and backup confidentiality, cluster availability,
and trustworthy monitoring evidence.

## Trust boundaries

- Internet clients cross Cloudflare before the selected public Gateway routes.
- GitLab CI crosses the registry and GitOps boundary when it publishes and promotes a
  digest.
- Argo CD crosses from reviewed Git state into Kubernetes admission.
- Workload service accounts cross the Kubernetes authentication boundary into OpenBao.
- Cluster backups cross the LAN boundary into the S3-compatible service.
- Administrator traffic crosses WARP private routing; the router exposes no inbound
  port.

## STRIDE analysis

| Threat | Representative abuse | Preventive or detective controls | Residual risk |
| --- | --- | --- | --- |
| Spoofing | An attacker presents an untrusted image or administrator identity | GitLab OIDC keyless signatures, Kyverno image verification, Keycloak MFA in Phase 10, local break-glass accounts | Signing and SSO are unproved until account and hardware tests complete |
| Tampering | Repository, deployment, backup, or runtime configuration is altered | Protected review flow, digest pins, Argo self-heal, SOPS bootstrap encryption, OpenBao audit log, versioned S3 | A compromised maintainer or CI runner can still propose or publish malicious state |
| Repudiation | An operator denies a secret, policy, or deployment change | Git history, GitLab job evidence, OpenBao audit storage, Argo events, Alertmanager history | Local emergency actions have weaker attribution and require a journal entry |
| Information disclosure | Secrets, private addresses, traces, or backups become public | Repository guards, scoped secrets, default-deny policies, internal observability, encrypted transport, no inbound router ports | Workload compromise may expose its own namespace data; S3 encryption is provider-dependent |
| Denial of service | Admission, storage, telemetry, or etcd exhausts the three nodes | HA controllers, PDBs, resource bounds, retention limits, scan concurrency caps, alerts, three replicas | The cluster has one power/LAN failure domain and finite disk/CPU capacity |
| Elevation of privilege | A Pod requests host access, root, or dangerous capabilities | PSA, Kyverno container controls, explicit infrastructure exception ledger, bounded service accounts | CNI, storage, and node monitoring retain necessary high privilege |

## Review triggers

Revisit this model when public routes change, an exception is added, identity or S3
providers change, phone workers join, a new CI runner is trusted, or a critical incident
invalidates an assumption. Runtime assertions remain `PENDING HARDWARE` until Anouar
records them in the verification ledger.
