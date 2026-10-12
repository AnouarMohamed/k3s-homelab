# Recover runtime secrets

## Sealed after restart

This is expected with manual Shamir unseal. Confirm pod and PVC identity, then follow
the unseal section of the initialization runbook for each voter. Do not initialize a
second time and do not delete a data PVC to make a pod start.

## Kubernetes authentication failure

Existing materialized Kubernetes Secrets remain available while refreshes fail. Pause
secret rotations, inspect the `ClusterSecretStore` condition and ESO logs, verify the
OpenBao certificate, and re-run the idempotent configuration script with the offline
root token. Do not replace Kubernetes auth with a static token Secret.

```bash
kubectl describe clustersecretstore openbao
kubectl -n external-secrets logs deployment/external-secrets --since=15m
kubectl -n openbao get certificate openbao-server
```

## Lost or suspected operator token

An operator token cannot alter policies or auth configuration and expires after eight
hours. Use the root token from offline custody to revoke it early by accessor, then
issue a replacement through the rotation runbook. Record the accessor and timestamps,
not the token value.

## Lost unseal shares or Raft quorum

Stop. Fewer than three surviving shares means this Shamir-sealed cluster cannot be
unsealed. Fewer than two healthy Raft voters means an ordinary leader election cannot
recover service. Do not initialize again, delete PVCs, or force a Raft restore while
applications are writing.

Preserve all PVCs and logs, identify the newest verified Raft snapshot, and open a
blameless incident record. Snapshot restoration is a destructive, hardware-only DR
procedure and must be rehearsed before it is trusted. Recovery is not complete until
ESO refreshes a non-production test secret and the audit log records the read.

## Break-glass principle

The offline root token and three independently held unseal shares are the local
break-glass path. They are deliberately outside Git, SOPS, Kubernetes, and OpenBao
itself. Rotate the root token and rekey shares after any custody breach; capture only
redacted evidence and never copy recovery material into the incident document.
