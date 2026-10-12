# Respond to platform alerts

Use this runbook from an authenticated administration session. Start by opening the
alert in Alertmanager, confirm its labels and start time, and check whether a planned
change explains it. Silence only the smallest matching label set and always add an
owner and expiry. Never suppress `Watchdog` to hide a broken notification path.

## Watchdog

The alert should always be firing. Confirm it exists in Prometheus and reaches the
configured receiver. If it disappears, check Prometheus rule evaluation. If it fires
but no notification arrives, inspect Alertmanager routing, the ExternalSecret, and the
receiver from a secure workstation without printing the secret value.

## Node down

Run `kubectl get nodes` and inspect the node-exporter target. Distinguish a failed node
from a blocked scrape before restarting anything. Check power, link, disk, and k3s
service state. Preserve etcd quorum: never take down a second server while one is lost.

## Etcd leader changes

Check `kubectl get --raw=/readyz?verbose` and the k3s journals on all three servers.
Look for packet loss, storage latency, clock drift, or a restarting member. Avoid
simultaneous changes and take an etcd snapshot before any recovery action.

## Disk pressure

Inspect node conditions, filesystem utilization, inode usage, Longhorn capacity, and
container logs. Identify the owning data before deleting anything. Use the relevant
retention or backup runbook; do not remove Kubernetes or Longhorn data by hand.

## Certificate expiry

Inspect the Certificate, CertificateRequest, Order, and Challenge resources. Confirm
DNS and the scoped Cloudflare credential are healthy. Use the staging issuer for a
diagnostic reissue and never delete the current serving Secret during investigation.

## Argo CD out of sync

Inspect the Application diff and recent GitLab commits. Resolve invalid desired state
in Git rather than live-editing a managed resource. Disable automated sync only for a
bounded incident, record why, and restore it after the repair is merged.

## Backup failure

Identify whether the failure came from Longhorn, CloudNativePG, or Velero. Check the
S3 endpoint, scoped credential status, capacity, and controller logs. Do not call a
retry successful until a new artifact exists and its restore metadata is readable.

## Longhorn degraded

Inspect the volume, replicas, node health, and disk scheduling state. Keep the workload
running when safe, restore replica count one volume at a time, and do not force-detach
from a live node. Escalate to the storage restore runbook if healthy replicas are lost.

## Container restarts

Inspect termination reason, events, probes, and prior logs. Determine whether the
restart is a crash, eviction, OOM, or failed dependency. Fix desired state in Git and
verify that the restart counter stops increasing before closing the incident.

## API latency

Compare API request latency with node CPU, memory, disk latency, etcd health, and noisy
controllers. Reduce optional reconciliation pressure before changing control-plane
settings. Preserve a timestamped metric snapshot for later review.

## SLO budget burn

Confirm the burn-rate window and failing SLI query. Correlate it with probe results,
deployments, and upstream dependencies. Stop risky releases while the budget is
burning, then record the user-visible interval and follow-up action.

After recovery, confirm the alert resolves, remove temporary silences, and create a
blameless incident record when availability or data durability was affected.
