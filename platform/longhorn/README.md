# Longhorn

Longhorn provides the default three-replica block StorageClass across the three
schedulable servers. The chart enables internal NetworkPolicies, recurring hourly
snapshots, daily S3 backups, and a Velero-selected CSI snapshot class. The V1 data
engine is retained for conservative bare-metal operation.

Operate it through the `longhorn` Argo CD Application. Run `make validate-storage`
offline; use the storage and restore runbooks before changing disks, replica counts,
or backup settings. Longhorn's required host and privileged access is documented as a
limited infrastructure exception and is verified in Policy and supply chain policy tests.
