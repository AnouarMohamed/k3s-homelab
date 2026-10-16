# Longhorn

Longhorn provides the default three-replica block StorageClass across the three
schedulable servers. The chart enables internal NetworkPolicies, recurring hourly
snapshots, daily S3 backups, and a Velero-selected CSI snapshot class. The V1 data
engine is retained for conservative bare-metal operation.

Logical volume scheduling is capped at 125% of usable disk capacity while the 25%
minimum-available guard remains enabled. This bounded thin-provisioning margin lets
CNPG enlarge an in-use WAL volume without claiming that the logical reservations are
physical utilization; operators must monitor both scheduled and actual bytes.

Operate it through the `longhorn` Argo CD Application. Run `make validate-storage`
offline; use the storage and restore runbooks before changing disks, replica counts,
or backup settings. Longhorn's required host and privileged access is documented as a
limited infrastructure exception and is verified in Policy and supply chain policy tests.
