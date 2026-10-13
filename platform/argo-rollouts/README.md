# Argo Rollouts

Argo Rollouts provides the canary controller used by Homelab Sentinel. The dashboard
is disabled; rollout state remains available through Argo CD and the guarded CLI.
The controller runs two replicas, exports metrics, and has a disruption budget and
default-deny network boundary.

Run `make validate-sentinel` to checksum, lint, render, and schema-check the chart.
