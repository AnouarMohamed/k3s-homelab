# Verify on hardware

Automation cannot mark any item in this document as passed. Run commands from a trusted
administration session after replacing the central configuration placeholders.

## Phase 1 — Nodes and k3s

Status: **PENDING HARDWARE**

```bash
ansible-playbook -i infra/ansible/inventory/hosts.yaml infra/ansible/site.yaml --check
make bootstrap-nodes
make bootstrap-nodes
kubectl get nodes -o wide
kubectl get --raw='/readyz?verbose'
sudo k3s etcd-snapshot ls
```

Expected: the second playbook run reports no changes; the VIP answers; all three server
nodes exist. Before Phase 2, `NotReady` because no CNI is expected.

## Phase 2 — Cilium

Status: **PENDING HARDWARE**

```bash
make bootstrap-cni
cilium status --wait
cilium connectivity test
kubectl get ciliuml2announcementpolicies,ciliumloadbalancerippools
```

Expected: Cilium is healthy, all nodes become Ready, connectivity tests pass, and the
pool reports available addresses without conflicts.

## Phases 3–12

Status: **PENDING HARDWARE**

Exact component-specific commands are added by each phase before it is marked
implemented. No runtime result is inferred from offline rendering.
