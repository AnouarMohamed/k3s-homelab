# Verify on hardware

Automation cannot mark any item in this document as passed. Run commands from a trusted
administration session after replacing the central configuration placeholders.

## Phase 1 — Nodes and k3s

Status: **PENDING HARDWARE**

```bash
ANSIBLE_CONFIG=infra/ansible/ansible.cfg \
  ansible-inventory -i infra/ansible/inventory/homelab.py --graph
ANSIBLE_CONFIG=infra/ansible/ansible.cfg \
  ansible-playbook -i infra/ansible/inventory/homelab.py infra/ansible/site.yaml --check
make bootstrap-nodes
make bootstrap-nodes
kubectl get nodes -o wide
kubectl get --raw='/readyz?verbose'
sudo k3s etcd-snapshot ls
sudo journalctl -u k3s --since '30 minutes ago' --no-pager
```

Expected: the second playbook run reports no changes; the VIP answers; all three server
nodes exist; auditd, fail2ban, UFW, chrony, and k3s are active; an S3 snapshot is
listed. Before Phase 2, `NotReady` because no CNI is expected.

## Phase 2 — Cilium

Status: **PENDING HARDWARE**

```bash
make bootstrap-cni
cilium status --wait
cilium connectivity test
kubectl get gatewayclass cilium
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl get ciliuml2announcementpolicies,ciliumloadbalancerippools
kubectl -n kube-system get leases | grep cilium-l2announce
cilium encrypt status
```

Expected: Cilium is healthy, all nodes become Ready, connectivity tests pass, and the
`cilium` GatewayClass is accepted. The pool reports available addresses without
conflicts, L2 announcement leases exist, and encryption status reports WireGuard on
all three nodes.

## Phase 3 — Argo CD

Status: **PENDING HARDWARE**

```bash
export SOPS_AGE_KEY_FILE=/secure/path/to/keys.txt
make bootstrap-gitops
kubectl -n argocd get pods,applications,applicationsets,appprojects
kubectl -n argocd get service argocd-server -o jsonpath='{.spec.type}{"\n"}'
kubectl -n argocd get application homelab-root argocd bootstrap-secrets cilium
kubectl -n argocd get deployment argocd-repo-server \
  -o jsonpath='{.spec.template.spec.automountServiceAccountToken}{"\n"}'
argocd app list
argocd account list
```

Expected: every Argo CD pod is Ready; the server is `ClusterIP`; the root, Argo CD,
bootstrap-secrets, and Cilium Applications are Healthy and Synced from GitLab `main`;
the production ApplicationSet uses the `applications` project; the default project has
no sources or destinations; repo-server token automount is `false`; and local `admin`
plus `platform-reader` accounts exist. Test a drift correction only on a harmless
ConfigMap and record the observed reconciliation before marking self-heal verified.

## Phases 4–12

Status: **PENDING HARDWARE**

Exact component-specific commands are added by each phase before it is marked
implemented. No runtime result is inferred from offline rendering.
