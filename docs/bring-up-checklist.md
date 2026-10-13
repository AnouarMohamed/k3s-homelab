# Bring-up checklist

I run these commands from a trusted administration session after replacing the central
configuration placeholders. I record only results I observe on the three PCs.

## Node provisioning: Nodes and k3s

Status: **not run yet**

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
listed. Before Cilium, `NotReady` because no CNI is expected.

## Cilium: Cilium

Status: **not run yet**

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

## Argo CD: Argo CD

Status: **not run yet**

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

## Edge traffic: Certificates, DNS, Tunnel, and WARP

Status: **not run yet**

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

## Storage and backups: Storage and backups

Status: **not run yet**

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

## Runtime secrets: Runtime secrets

Status: **not run yet**

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
rotation, revocation, and recovery remain unverified until I records those results.

## Observability: Observability

Status: **not run yet**

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
delivery, probe results, and SLO evaluation remain unverified until I records the
observations.

## Policy and supply chain: Policy and supply chain

Status: **not run yet**

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
completed. GitLab OIDC signature acceptance remains pending the Sentinel signed image.

## Sentinel: Homelab Sentinel and delivery

Status: **not run yet**

After the GitLab variables in `setup.md` are protected and populated, run a
default-branch pipeline and retain links to every job. Verify that the image indexes
contain both target platforms, all security gates passed, and the GHCR references are
digest-addressable:

```bash
docker buildx imagetools inspect \
  registry.gitlab.com/<project>/homelab-sentinel-api@sha256:<digest>
docker buildx imagetools inspect \
  registry.gitlab.com/<project>/homelab-sentinel-worker@sha256:<digest>
cosign verify \
  --certificate-identity 'https://gitlab.com/<project>//.gitlab-ci.yml@refs/heads/main' \
  --certificate-oidc-issuer https://gitlab.com \
  registry.gitlab.com/<project>/homelab-sentinel-api@sha256:<digest>
oras manifest fetch ghcr.io/<namespace>/homelab-sentinel-deploy@sha256:<digest>
```

Expected: both image indexes list `linux/amd64` and `linux/arm64`; Cosign verifies a
GitLab OIDC signature and Rekor entry; GHCR contains API, worker, and deployment
packages copied from the successful pipeline. No result is inferred from the CI
configuration alone.

After Argo CD syncs staging and the manual production promotion is approved:

```bash
kubectl argo rollouts get rollout sentinel-api -n apps-sentinel-staging
kubectl argo rollouts get rollout sentinel-api -n apps-sentinel
kubectl get analysiruns,pods,pdb,hpa -n apps-sentinel
kubectl get cluster sentinel-database -n apps-sentinel
kubectl get scheduledbackup sentinel-database -n apps-sentinel
kubectl run sentinel-check --rm -i --restart=Never \
  --image=curlimages/curl@sha256:<reviewed-digest> -- \
  curl --fail http://sentinel-api.apps-sentinel.svc:8080/readyz
curl --fail https://status.<configured-domain>/api/v1/status
```

Expected: staging and production Rollouts are Healthy, analysis runs succeed, the HPA
and PDB exist, all three production database instances are healthy, scheduled backups
have successful status, readiness returns 200, and the public endpoint returns only
the selected service status fields. Replace the diagnostic image placeholder with a
reviewed immutable digest before running it.

Exercise a canary abort, node reschedule, database failover, S3 recovery, and the
rollback runbook. Record real timestamps and evidence in the Sentinel result tables;
do not copy expected values into results.

## Identity and apps: Identity and self-hosted applications

Status: **not run yet**

```bash
kubectl -n keycloak get deploy,cluster,scheduledbackup,servicemonitor,httproute
kubectl -n apps-vaultwarden get deploy,cluster,pvc,scheduledbackup,httproute
kubectl -n apps-homepage get deploy,pdb,httproute
kubectl -n apps-uptime-kuma get deploy,pvc,httproute
```

Expected: Keycloak has two available replicas, both CNPG clusters have three healthy
instances, routes attach only to the internal Gateway, and every ExternalSecret is
Ready. Verify Argo CD and Grafana login for both groups, mandatory TOTP enrollment,
local break-glass login, a Keycloak pod eviction, a CNPG failover, a Vaultwarden backup,
and a Velero restore. Record real timestamps and observations; do not infer success.

## Chaos and recovery: Chaos and disaster recovery

Status: **not run yet**

```bash
kubectl get namespaces -o json | \
  yq -r '.items[] | select(.metadata.annotations."chaos-mesh.org/inject" == "enabled") | .metadata.name'
kubectl -n chaos-mesh get deploy,daemonset,pods,networkpolicy
kubectl -n chaos-testing get deploy,pods,pdb,networkpolicy
make test-chaos CONFIRM_CHAOS=homelab
```

Expected: only `chaos-testing` is injection-enabled; three controller replicas and one
daemon per node are Ready; every experiment remains in `chaos-testing`, finishes within
its declared duration, and the target returns to three Ready replicas. Run the seven DR
drills separately and leave every results table empty until real measurements exist.

## Documentation

Status: **not run yet**

After every earlier check is complete, open the README as a new visitor and follow
each architecture, evidence, ADR, runbook, status, and security link. Confirm that no
link exposes an administrative endpoint and that every public URL matches
`docs/security/public-surface.md`.

Capture the six exact files in `docs/img/README.md`, then inspect their metadata and
pixels before committing them. Domains, addresses, tokens, account identifiers,
emails, browser history, and unrelated tabs must be absent or redacted. Link the
approved images from the relevant evidence rows.

```bash
make validate-portfolio
make validate
make security
git status --short
```

Expected: every command exits zero, the worktree contains only the deliberately added
redacted evidence, and every status claim points to observed output. I reviews the
five-minute walkthrough and is the only person who may change hardware status to
`Verified`.
