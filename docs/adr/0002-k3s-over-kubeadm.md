# Choose k3s over Kubeadm for Homelab Kubernetes

## Status
Accepted

## Context
We need to install a Kubernetes cluster on three Ubuntu Server LTS nodes for the homelab. The cluster should be lightweight, easy to maintain, and suitable for a resource-constrained environment while still being production-grade.

## Decision
We chose k3s as the Kubernetes distribution instead of kubeadm for the following reasons:
- k3s is lightweight, with a small binary and minimal dependencies, ideal for homelab hardware.
- It bundles etcd, CNI, and other components, reducing operational complexity.
- k3s supports embedded etcd for HA clusters, which fits our three-node requirement.
- It simplifies installation and upgrades with a single script or automated Ansible playbook.
- k3s has built-in support for running control-plane nodes as workers, maximizing resource utilization.
- The default installation includes Flannel, but we will replace it with Cilium (see ADR 0003).

## Consequences
- We will use k3s v1.28.x or later, pinned to a specific version.
- The cluster will be installed using Ansible playbooks in the `infra/ansible/` directory.
- We will disable the default Flannel CNI and install Cilium instead.
- Future upgrades of k3s will be managed through the Ansible playbook and GitOps practices.