# Node automation

The dynamic inventory reads all three names, addresses, and interfaces directly from
`config/homelab.yaml`. Set `HOMELAB_ANSIBLE_USER` when the automation account is not
named `ansible`.

## Runtime secrets

Export `K3S_TOKEN`, `K3S_S3_ACCESS_KEY`, and `K3S_S3_SECRET_KEY` from a secure SOPS
workflow or password manager before running a playbook. They are asserted at runtime,
marked `no_log` where templated, and written only to root-readable k3s configuration on
the nodes. No secret defaults exist in Git.

## Ordering

`site.yaml` performs four distinct steps:

1. prepare and harden all nodes;
2. initialize k3s on the first configured node;
3. install kube-vip there and wait for the API VIP;
4. join the other two nodes serially through that VIP and add kube-vip to each.

The playbook validates API health and node registration, but deliberately does not wait
for the Kubernetes Ready condition. `NotReady` is expected until Cilium installs
Cilium.

Use `make bootstrap-nodes`, `make upgrade-k3s`, and the doubly guarded `make reset
CONFIRM_RESET=homelab`. Real execution is reserved for I and remains
`not run yet`.
