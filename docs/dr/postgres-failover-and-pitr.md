# PostgreSQL failover and point-in-time recovery

Status: **not run yet**

## Preconditions

- Choose the Sentinel verification database, not Keycloak or Vaultwarden first.
- Confirm three healthy instances, a completed base backup, continuous WAL archival,
  and a timestamped marker row.
- Define a new recovery-cluster name; never overwrite the source cluster.

## Procedure

1. Delete or stop the current primary pod and measure automatic promotion while reads
   and bounded writes continue.
2. Confirm the old primary rejoins and the marker remains visible.
3. Add a second marker, record its timestamp, then create a separate recovery Cluster
   from the base backup with a PITR target between the two markers.
4. Verify the first marker exists, the second does not, and archived WAL remains intact.

## Rollback

Stop writes if promotion exceeds the abort threshold. Delete only the separate recovery
cluster after evidence capture; do not modify the source backup or WAL archive.

Expected: CNPG promotes once without split brain, and PITR reaches the selected time
with the exact expected marker boundary.

## Results

| Started at | Cluster | Promotion time | PITR target | Recovery time | Data loss | Lessons |
| --- | --- | --- | --- | --- | --- | --- |
