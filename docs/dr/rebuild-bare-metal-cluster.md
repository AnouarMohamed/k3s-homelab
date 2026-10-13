# Rebuild the bare-metal cluster

Status: **PENDING HARDWARE**

## Preconditions

- Treat this as the final drill after component restore drills pass.
- Record and verify the newest etcd snapshot, CNPG base backups/WAL, Velero backup,
  OpenBao recovery material, age identity, central config, and Git commit.
- Prepare three blank disks and an isolated recovery network; preserve original disks.

## Procedure

1. Install the pinned Ubuntu baseline on all nodes and restore static networking.
2. Run Ansible through the expected pre-CNI `NotReady` state; install Cilium and verify
   node readiness.
3. Restore etcd from S3 or bootstrap GitOps according to the chosen recovery objective.
4. Initialize/unseal OpenBao with preserved recovery material, restore CNPG and Velero
   data into new objects, and reconcile Argo CD.
5. Validate identity, public status, monitoring, backups, and one controlled failover.

## Rollback

Keep original disks offline and unchanged. If a recovery checkpoint fails, stop before
DNS or tunnel cutover, archive logs, and restart from blank recovery disks.

Expected: the platform is reproducible from Git plus separately protected recovery
material, with measured recovery time and explicitly measured data loss.

## Results

| Started at | Git commit | Recovery points | Platform recovery | Data recovery | Data loss | Lessons |
| --- | --- | --- | --- | --- | --- | --- |
