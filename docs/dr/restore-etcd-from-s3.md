# Restore embedded etcd from S3

Status: **PENDING HARDWARE**

## Preconditions

- Use an isolated recovery window with application writes stopped.
- Record the S3 snapshot name, checksum, creation time, and expected recovery point.
- Preserve all original k3s data directories and central configuration.

## Procedure

1. Download and verify the chosen snapshot using the documented k3s S3 credentials.
2. On `pc-1`, run the k3s cluster-reset restore command from the replacement runbook
   with the exact snapshot name; do not run it from this automation session.
3. Start `pc-1`, verify the API and single-member etcd health, then rejoin `pc-2` and
   `pc-3` serially using the normal server-token path.
4. Reconcile Argo CD and compare critical object counts with the pre-drill record.

## Rollback

Stop k3s and restore the preserved data directories if snapshot validation fails before
member rejoin. After writes resume, rollback requires another planned restore.

Expected: the three-member cluster returns at the recorded snapshot recovery point,
with GitOps reconciling only changes made after that point.

## Results

| Started at | Snapshot | Recovery point | API recovery | Full recovery | Data loss | Lessons |
| --- | --- | --- | --- | --- | --- | --- |
