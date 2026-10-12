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

## Phase 4 — Certificates, DNS, Tunnel, and WARP

Status: **PENDING HARDWARE**

```bash
tofu -chdir=infra/tofu plan -refresh=false
kubectl -n cert-manager get pods
kubectl get clusterissuer letsencrypt-staging letsencrypt-production
kubectl -n gateways get certificate edge-wildcard
kubectl -n gateways get gateway internal public
kubectl -n external-dns logs deployment/external-dns --tail=100
kubectl -n cloudflare get pods -l app.kubernetes.io/name=cloudflared -o wide
kubectl -n apps-whoami get httproute whoami
curl --fail --show-error "https://whoami.${DOMAIN}/health"
```

Expected: the reviewed OpenTofu plan contains only the Tunnel, private route, and
whoami CNAME changes; both issuers become Ready; the wildcard certificate is issued;
both Gateways are accepted; the two tunnel replicas occupy different nodes; the route
is accepted; and the public health request succeeds without an inbound router port.
From an enrolled WARP client, verify the private CIDR and split-DNS internal hostname;
repeat from an unenrolled client and confirm administration endpoints are unreachable.
Delete or disable the temporary whoami route after capturing redacted evidence.

## Phase 5 — Storage and backups

Status: **PENDING HARDWARE**

```bash
kubectl get storageclass
kubectl -n longhorn-system get pods -o wide
kubectl -n longhorn-system get nodes.longhorn.io,recurringjobs.longhorn.io
kubectl get volumesnapshotclass longhorn-snapshot
kubectl -n cnpg-system get deploy,pod -o wide
kubectl -n storage-verification get clusters.postgresql.cnpg.io,scheduledbackups
kubectl -n storage-verification get objectstores.barmancloud.cnpg.io
kubectl -n velero get backupstoragelocations.velero.io,schedules.velero.io
CONFIRM_STORAGE_TEST=homelab make test-storage-reschedule
```

Expected: `longhorn` is the sole default class; every Longhorn volume has three healthy
replicas on distinct nodes; both controller replicas are spread; the CNPG cluster has
one primary and two healthy replicas; WAL archive status is healthy; Velero's backup
location is Available; and the marker survives movement to a different node. Then run
`docs/dr/restore-drill-storage.md`. Scheduled backups, restores, replica recovery, and
measured recovery time remain unverified until that empty results table is filled.

## Phase 6 — Runtime secrets

Status: **PENDING HARDWARE**

Follow `docs/runbooks/initialize-and-unseal-openbao.md`; never copy recovery values into
the verification log. Then run only the non-secret status checks below.

```bash
kubectl -n openbao get pods,pvc -o wide
kubectl -n openbao get certificate openbao-server
kubectl exec -n openbao openbao-0 -- \
  env BAO_ADDR=https://127.0.0.1:8200 BAO_CACERT=/openbao/tls/ca.crt \
  bao status
kubectl get clustersecretstore openbao
kubectl -n external-secrets get deploy,pod -o wide
kubectl auth can-i create serviceaccounts/token \
  --as=system:serviceaccount:external-secrets:external-secrets \
  --resource-name=openbao-auth -n external-secrets
kubectl auth can-i create serviceaccounts/token \
  --as=system:serviceaccount:external-secrets:external-secrets \
  --resource-name=default -n external-secrets
```

Expected: one active and two standby OpenBao voters are unsealed, all data and audit
PVCs are Bound, the TLS certificate is Ready, the store is Ready, and all six ESO pods
are spread across the three nodes. The exact TokenRequest is allowed and the request
for `default` is denied. Perform a test rotation, confirm ESO refresh and an audit-log
entry without recording the value, then restart voters one at a time and manually
unseal each. Initialization, unseal, Raft failover, audit persistence, authentication,
rotation, revocation, and recovery remain unverified until Anouar records those results.

## Phase 7 — Observability

Status: **PENDING HARDWARE**

```bash
kubectl -n monitoring get pods,pvc -o wide
kubectl -n monitoring get prometheus,alertmanager,prometheusrules
kubectl -n monitoring get servicemonitors,podmonitors,probes
kubectl -n monitoring get prometheusservicelevels.sloth.slok.dev
kubectl -n monitoring get externalsecret alertmanager-notification
kubectl -n argocd get externalsecret argocd-notifications
kubectl -n monitoring port-forward service/monitoring-kube-prometheus-prometheus 9090:9090
curl --fail --show-error http://127.0.0.1:9090/-/ready
curl --fail --show-error 'http://127.0.0.1:9090/api/v1/query?query=ALERTS%7Balertname%3D%22Watchdog%22%7D'
kubectl -n monitoring exec statefulset/loki -- wget -qO- http://127.0.0.1:3100/ready
kubectl -n monitoring exec statefulset/tempo -- wget -qO- http://127.0.0.1:3200/ready
kubectl -n monitoring logs deployment/alloy --all-containers --tail=100
kubectl -n monitoring logs deployment/otel-collector-opentelemetry-collector --tail=100
kubectl -n monitoring get configmap homelab-platform-dashboards
kubectl -n monitoring get alertmanagerconfig platform -o yaml
```

Expected: every controller is Ready and spread where configured; all PVCs are Bound;
Prometheus has two replicas and Alertmanager has three; targets and rule groups are
healthy; `Watchdog` is firing and reaches the configured receiver; both ExternalSecrets
are Ready without exposing their values; Loki and Tempo return ready; Alloy sends pod
logs to Loki; an OTLP test trace reaches Tempo; all seven dashboards load with working
data sources; and blackbox probes succeed. Measure storage growth for one week before
changing retention. Notification delivery, dashboard content, log collection, trace
delivery, probe results, and SLO evaluation remain unverified until Anouar records the
observations.

## Phase 8 — Policy and supply chain

Status: **PENDING HARDWARE**

```bash
kubectl -n kyverno get deploy,pod,pdb,networkpolicy
kubectl get validatingpolicies.policies.kyverno.io
kubectl get imagevalidatingpolicies.policies.kyverno.io
kubectl get clusterpolicy require-network-policy
kubectl get clusterpolicyreports.wgpolicyk8s.io
kubectl -n trivy-system get deploy,pod,networkpolicy,servicemonitor
kubectl get vulnerabilityreports.aquasecurity.github.io --all-namespaces
kubectl get configauditreports.aquasecurity.github.io --all-namespaces
kubectl get rbacassessmentreports.aquasecurity.github.io --all-namespaces
kubectl get sbomreports.aquasecurity.github.io --all-namespaces
kubectl -n monitoring get prometheusrule homelab-security-findings
kubectl -n monitoring get configmap homelab-security-posture-dashboard
kubectl auth can-i create validatingpolicies.policies.kyverno.io \
  --as=system:serviceaccount:apps-whoami:default
kubectl auth can-i get vulnerabilityreports.aquasecurity.github.io \
  --as=system:serviceaccount:apps-whoami:default -n apps-whoami
sed 's/namespace: apps-invalid/namespace: apps-whoami/' \
  policies/tests/resources/invalid-pod.yaml | \
  kubectl apply --server-side --dry-run=server -f -
```

Expected: all Kyverno controllers are Ready with the configured replica counts and
spread; both namespaces have a default-deny NetworkPolicy; six CEL validation policies,
one image policy, and the matching-NetworkPolicy policy exist in Audit mode; the Trivy
operator has two Ready replicas and produces fresh reports without node-collector jobs;
both service-account authorization checks return `no`; the dashboard loads and the
critical-finding alert evaluates from Trivy metrics. The invalid dry-run is admitted
with Audit findings before promotion and denied only after the enforcement runbook is
completed. GitLab OIDC signature acceptance remains pending the Phase 9 signed image.

## Phases 9–12

Status: **PENDING HARDWARE**

Exact component-specific commands are added by each phase before it is marked
implemented. No runtime result is inferred from offline rendering.
