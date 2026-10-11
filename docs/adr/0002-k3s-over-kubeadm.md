# Choose k3s over kubeadm

## Status

Accepted

## Context

The homelab needs a highly available Kubernetes control plane on three modest Ubuntu
Server nodes. All control-plane nodes must also remain schedulable.

## Decision

Use k3s with embedded etcd. Pin the release to `v1.36.5+k3s1`, verify the downloaded
binary checksum, and install it through Ansible. Disable Flannel, kube-proxy, the
built-in network-policy controller, Traefik, and ServiceLB at installation time so
Cilium can own those functions without a migration from a live CNI.

k3s retains the upstream Kubernetes API while reducing the number of separately
managed binaries. Its embedded etcd mode fits the required three-member quorum, and
the server nodes can run workloads.

## Consequences

- Ansible must control installation order, flags, snapshots, and rolling upgrades.
- Nodes are expected to remain `NotReady` between k3s and Cilium bootstrap.
- The platform depends on k3s packaging and must validate upgrades against the Cilium
  compatibility matrix before changing Kubernetes minors.
- kubeadm-specific operational procedures do not apply.
