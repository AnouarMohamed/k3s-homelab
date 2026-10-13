# ADR 0009: Layered storage and backup

## Context

I need local replicated storage to survive a single-node outage, database-aware
point-in-time recovery, and cluster-resource backups that remain useful after a total
cluster loss. No one layer provides all three properties.

## Decision

I use Longhorn V1 volumes with three replicas for general local availability. Database
volumes use two Longhorn replicas because CloudNativePG already keeps three database
instances on separate nodes. I use the CNPG-I Barman Cloud plugin for PostgreSQL WAL
archival and physical base backups, and Velero for Kubernetes resources plus Longhorn
CSI snapshots. Longhorn and Velero use separate S3 prefixes and credentials; CNPG uses
a third. `local-path` remains installed but is directly non-default.

## Rejected alternatives

- I rejected local-path as the default because a volume is tied to one node.
- I rejected Longhorn backups as the only database protection because crash-consistent
  volume copies do not replace PostgreSQL-aware WAL archival and PITR.
- I rejected Velero filesystem backup for Storage and backups because Longhorn exposes CSI
  snapshots and the extra privileged node agent is unnecessary.
- I rejected a vendor-specific S3 provider because the central contract identifies
  only an S3-compatible endpoint and bucket; I create the bucket after
  the service is selected.

## Tradeoffs

Three replicas consume three times the raw capacity and Longhorn needs privileged host
access. The layered approach costs more storage and operational attention, but it
separates availability, database recovery, and cluster recovery. None is considered
proven until I complete the restore drill. The exact Longhorn exception and its
compensating controls are recorded in the
[infrastructure exception checklist](../security/infrastructure-exceptions.md).
