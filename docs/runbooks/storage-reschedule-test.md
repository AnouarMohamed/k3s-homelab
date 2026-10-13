# Run the storage reschedule test

The test is limited to the `storage-verification` Deployment and PVC. It temporarily
cordons the pod's node, deletes that test pod, waits for a replacement on another node,
checks the persisted marker, and always attempts to uncordon the node.

```bash
kubectl get nodes
kubectl -n storage-verification get deploy,pod,pvc -o wide
CONFIRM_STORAGE_TEST=homelab make test-storage-reschedule
kubectl get nodes
```

Do not run during another node drain. If the script exits early, manually run
`kubectl uncordon <node>` and verify all nodes are schedulable. Record the two node
names and observed marker result in the hardware checklist; do not invent a duration.
