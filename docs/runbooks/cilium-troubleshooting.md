# Troubleshoot Cilium bootstrap

## First checks

```bash
kubectl get crd gatewayclasses.gateway.networking.k8s.io
helm --namespace kube-system status cilium
kubectl --namespace kube-system get pods -o wide
cilium status --wait
cilium connectivity test
```

Before changing values, run `make validate-cni` and compare the deployed Helm values
with the in-memory render. Never paste the rendered VIP or LAN range into a tracked
debug file.

## Common failure boundaries

| Symptom | Check | Safe response |
| --- | --- | --- |
| Nodes stay `NotReady` | Cilium agent init logs, kernel modules, cgroup v2 | Fix the node prerequisite; do not add a second CNI |
| Agent cannot reach API | VIP reachability, TCP 6443, `k8sServiceHost` render | Restore kube-vip/firewall before changing Cilium |
| No LoadBalancer address | Pool conflicts, start/stop render, service events | Correct central config and reconcile the pool |
| Address allocated but unreachable | L2 lease holder, interface regex, UFW, ARP table | Fix selector/interface; do not add router forwarding |
| WireGuard absent | `cilium encrypt status`, UDP 51871, kernel module | Restore peer firewall/module and restart one agent at a time |
| Gateway rejected | Gateway API CRD version and GatewayClass status | Reapply the checksum-verified CRDs before the chart |

## Recovery

The bootstrap command is idempotent and uses the same values source later adopted by
Argo CD. Roll back only to a chart/k3s pair already recorded as compatible. Do not
uninstall Cilium from a remote-only session: removing the active CNI can sever API and
workload access. Capture `cilium sysdump` outside Git before escalation.
