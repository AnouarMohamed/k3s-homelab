# Rebuild one node

Status: **PENDING HARDWARE**

## Preconditions

- Confirm the other two servers are healthy, retain etcd quorum, and own good storage
  replicas. Record the failed member name and hardware identifiers.
- Confirm current etcd, CNPG, Longhorn, and Velero backups.
- Keep the replacement node disconnected until its static address is configured.

## Procedure

1. Remove the permanently failed member only after proving it cannot return.
2. Install the pinned Ubuntu Server LTS baseline and the original static node identity.
3. Run the Ansible site playbook for that host and join it serially to the k3s servers.
4. Verify etcd membership, Cilium, storage replicas, scheduling, and a second idempotent
   playbook run.

## Rollback

Power off the replacement if it presents a duplicate node or etcd identity. Do not
remove another member; restore the preserved original disk only under the quorum runbook.

Expected: the node returns from source-controlled automation, etcd has three unique
members, and storage re-replicates without data loss.

## Results

| Started at | Node | Provision time | Join time | Full recovery | Data loss | Lessons |
| --- | --- | --- | --- | --- | --- | --- |
