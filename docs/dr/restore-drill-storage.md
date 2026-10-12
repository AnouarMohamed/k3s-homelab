# Storage restore drill

Status: **PENDING HARDWARE**

## Objective

Prove that a Longhorn-backed PVC, a CloudNativePG database, and a Velero namespace
backup can be restored without relying on the original workload objects.

## Preconditions

- Record cluster health and confirm no other maintenance is active.
- Select completed Longhorn, Barman Cloud, and Velero backups; do not use a running
  schedule as proof that an object is recoverable.
- Use new restore names in `storage-verification`; never overwrite the source.
- Define the rollback as deletion of only the temporary restore objects.

## Procedure

1. Restore the reschedule PVC from a Longhorn backup into a new PVC and compare its
   marker.
2. Restore the verification PostgreSQL cluster from the selected Barman base backup
   and WAL archive into a new Cluster, then compare database identity and row counts.
3. Restore `storage-verification` with Velero under a temporary namespace mapping and
   verify Kubernetes resources plus the CSI-restored volume.
4. Remove temporary restore objects after evidence is captured.

Expected: all three restored data sets match their recorded source checks without
modifying the source objects. Any missing object, unbounded WAL replay, or inconsistent
marker is a failed drill.

## Results

| Started at | Backup identifiers | PVC result | PostgreSQL result | Velero result | Recovery time | Data loss | Lessons |
| --- | --- | --- | --- | --- | --- | --- | --- |
