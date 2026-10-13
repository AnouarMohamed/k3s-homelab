# Operate storage and backups

## Preconditions

Complete the S3 and disk-path items in `docs/setup.md`, re-encrypt the three scoped
credential placeholders, and confirm every node has the required Longhorn host
packages. The default policies allow object-storage traffic only over HTTPS port 443.
Do not proceed when any disk contains data that may be overwritten.

## Bring-up checks

1. Sync `storage-secrets`, `snapshot-controller`, `longhorn`, `cloudnative-pg`,
   `velero`, then `storage-verification` in wave order.
2. Confirm `longhorn` is the only default StorageClass and every Longhorn node has one
   schedulable disk at the central path.
3. Confirm the verification database has one primary and two streaming replicas on
   distinct nodes.
4. Inspect Longhorn, CNPG, and Velero backup targets without printing credentials.
5. Trigger one backup in each layer and retain the object names as redacted evidence.

## Disk or replica degradation

Stop before deleting a volume or replica. Check node/disk conditions, free capacity,
engine state, and replica placement. Repair host connectivity first. Allow automatic
rebuild to complete and verify all three replicas before draining another node.

## Tests

Run `make validate-storage` offline. On hardware, follow the Storage and backups checklist and the
restore drill. A green scheduled-backup status is not recovery evidence.
