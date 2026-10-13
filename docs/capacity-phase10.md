# Phase 10 capacity budget

These are Kubernetes limits, not observed consumption. Hardware utilization remains
`PENDING HARDWARE`.

| Component | Replicas | CPU requests | Memory requests | Persistent data |
| --- | ---: | ---: | ---: | ---: |
| Keycloak | 2 | 500m | 1.5 GiB | CNPG: 36 GiB requested |
| Vaultwarden | 1 | 100m | 128 MiB | 5 GiB + CNPG: 36 GiB requested |
| Homepage | 2 | 100m | 256 MiB | None |
| Uptime Kuma | 1 | 100m | 192 MiB | 5 GiB |

The two CNPG clusters request six database pods at 100m CPU and 256 MiB each. Before I
enable an optional app, I will record 30 days of node CPU, memory, and Longhorn capacity
and keep at least one node's requested capacity free. Optional apps remain choices in
`HUMAN_TODO.md`, not planned deployments.
