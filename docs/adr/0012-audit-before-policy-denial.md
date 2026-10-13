# ADR 0012: Audit application policy before denial

## Context

Admission policy can prevent insecure workloads, but enabling broad denial before the
existing GitOps tree is measured risks blocking recovery controllers and required host
access. Kyverno 1.19 also introduces stable CEL-native policy APIs while deprecating its
legacy policy type.

## Decision

I use Kyverno 1.19 CEL `ValidatingPolicy` and `ImageValidatingPolicy` resources for
application controls. GitOps deploys the Audit overlay. A separately rendered and tested
overlay changes the actions to `Deny`; promotion requires clean reports and the runbook.

Application policy is selected by a positive namespace label. Keyless signature and
GitLab-registry restrictions require a second supply-chain label, so third-party
infrastructure is never silently treated as repository-built software. Pod Security
Admission remains an independent minimum boundary.

The matching-NetworkPolicy inventory rule temporarily remains a legacy
`ClusterPolicy`: the pinned CEL validation schema does not expose Kyverno's Kubernetes
API-call context. It is the only legacy rule and must be migrated or replaced before a
Kyverno 1.20 upgrade.

## Rejected alternatives

- Immediate Deny mode: rejected because offline renders cannot prove admission behavior
  or enumerate runtime-generated Pods.
- Namespace-wide infrastructure exclusions: rejected because they conceal unrelated
  workloads and make exceptions difficult to review.
- Deploying Kubescape alongside Kyverno and Trivy: rejected for overlapping coverage
  and resource cost on three small nodes.
- Disabling signature checks until the demo app exists: rejected because the admission
  contract should exist before the first owned image is promoted.

## Tradeoff

Audit mode detects but does not initially block a violation. The staged approach makes
the transition observable and reversible, while the specific promotion step remains a
human operational responsibility. One legacy rule adds known upgrade work.
