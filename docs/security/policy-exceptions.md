# Policy exceptions

Exceptions are scoped to infrastructure that cannot technically meet an application
control. Application namespaces do not inherit these exceptions.

| Component | Narrow exception | Reason | Compensating control |
| --- | --- | --- | --- |
| Cilium | Host networking, host mounts, elevated capabilities | CNI and eBPF lifecycle | Pinned image, kube-system only, Cilium policies, audited upgrade |
| kube-vip | Host networking and NET_ADMIN | ARP control-plane VIP | Static pod, pinned digest, control-plane nodes only |
| Longhorn | Privileged containers and host mounts | Block-device and replica management | Dedicated namespace, default-deny boundary, three replicas |
| node-exporter | Host PID/network and read-only host mounts | Node-level metrics | Monitoring-only scrape path and pinned digest |
| Alloy | Read-only host log mounts | Node log collection | Default-deny egress and monitoring namespace isolation |
| Trivy node collector | Host mounts | Node configuration inspection | Disabled; kube-bench remains a human-run hardware check |

Kyverno application controls select only namespaces labeled
`policy.homelab.dev/profile: application`. The separate `supply-chain: signed` label is
reserved for images built and keylessly signed by this repository. Any future exception
must name the workload, control, owner, expiry, and compensating control before merge.
