# Choose Cilium over Flannel

## Status

Accepted

## Context

The cluster needs kube-proxy replacement, network-policy enforcement, Gateway API,
load-balancer address management, LAN L2 announcements, pod-traffic encryption, and
flow visibility. Flannel alone does not provide that integrated feature set.

## Decision

Install Cilium `1.20.2` directly into the CNI-free k3s cluster. Enable strict
kube-proxy replacement, Gateway API, LB IPAM, L2 announcements, Hubble, Prometheus
metrics, and WireGuard encryption. Install the pinned Gateway API CRDs first.

The bootstrap configuration and the Argo CD-managed configuration must render from the
same values so adoption cannot silently change networking.

## Consequences

- Cilium becomes a bootstrap-critical dependency and must be recoverable without Argo
  CD.
- Kernel, firewall, API VIP, interface-selector, and Kubernetes-version compatibility
  require explicit validation.
- Baseline namespace policies deny traffic by default and add narrow DNS and
  same-namespace allowances.
- Connectivity, L2 failover, and encryption checks remain `PENDING HARDWARE` until
  Anouar runs them.
