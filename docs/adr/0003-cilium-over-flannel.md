# Choose Cilium over Flannel for CNI

## Status
Accepted

## Context
After installing k3s with the default Flannel CNI, we need to replace it with a CNI that provides advanced networking, security, and observability features suitable for a production-grade homelab. The CNI must support NetworkPolicy (since we disable kube-proxy), Hubble for visibility, and ideally integrate with Gateway API.

## Decision
We chose Cilium as the CNI plugin over Flannel (and other options like Calico, Weave) because:
- Cilium replaces kube-proxy with eBPF-based forwarding, offering better performance and scalability.
- It provides built-in NetworkPolicy enforcement, which we require for all workloads.
- Hubble offers deep visibility into network flows and security events.
- Cilium supports Gateway API out of the box, aligning with our goal of using modern Kubernetes APIs.
- It integrates well with other tools in our stack, such as Istio (if adopted later) and Prometheus for metrics.
- The installation is straightforward via Helm chart, which we will manage via Argo CD.

## Consequences
- We will disable the default network policy controller in k3s (as noted in AGENTS.md).
- We will install Cilium via its Helm chart, version pinned in the platform/Cilium directory.
- All namespaces will have baseline Network Policies applied via Kyverno (see policies/ directory).
- We will monitor network performance and security using Hubble and integrate metrics with Prometheus.