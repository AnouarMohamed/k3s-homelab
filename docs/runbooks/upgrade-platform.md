# Upgrade the platform

Upgrade one dependency family per change. Never combine a Kubernetes minor upgrade with
network, storage, identity, or policy-controller changes.

1. Read upstream release notes and compatibility matrices; update the exact pin,
   checksum or digest, Renovate rule, `PLAN.md`, and `docs/compatibility.md`.
2. Fetch from the official source, run the phase validator twice, then run `make lint`,
   `make validate`, and `make security`.
3. Confirm current etcd, CNPG, Longhorn, and Velero backups and test the relevant restore
   path. Record abort thresholds and the previous known-good Git commit.
4. Reconcile staging or the least risky controller first. Observe alerts, API errors,
   resource use, and CRD conversion before proceeding.
5. For k3s, preserve etcd quorum. For CRD controllers, follow the upstream CRD order.
6. Run hardware verification and a safe failover. Roll back through Git or the component
   recovery runbook; never downgrade a data format blindly.

Do not mark an upgrade verified from a successful render alone.
