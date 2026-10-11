# Node firewall matrix

UFW denies unsolicited host input, allows host output, and permits forwarding so
Cilium can enforce pod traffic. `adminCidr` comes from `config/homelab.yaml`; node
addresses are read from the same file.

| Source | Protocol/port | Purpose |
| --- | --- | --- |
| Administrator CIDR | TCP 22 | SSH automation and break-glass administration |
| Administrator CIDR | TCP 80, 443 | Internal Gateway endpoints |
| Administrator CIDR | TCP 6443 | Kubernetes API through LAN or WARP private route |
| Cluster nodes | TCP 2379–2380 | Embedded etcd client and peer traffic |
| Cluster nodes | TCP 6443 | Kubernetes API and server joins |
| Cluster nodes | TCP 10250 | Kubelet API |
| Cluster nodes | TCP 4240, 4244 | Cilium health and Hubble peer traffic |
| Cluster nodes | UDP 8472 | Cilium VXLAN overlay |
| Cluster nodes | UDP 51871 | Cilium WireGuard |

No rule opens a router port. Later phases must update this table and role before adding
host-listening services. Public HTTP traffic enters through outbound cloudflared
connections rather than a WAN firewall rule.
