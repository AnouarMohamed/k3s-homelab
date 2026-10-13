# Alert to runbook map

| Alert family | Runbook |
| --- | --- |
| Watchdog, node, etcd, disk, certificate, Argo CD, backup, Longhorn, restart, API latency | [Respond to platform alerts](respond-to-platform-alerts.md) |
| Critical container vulnerability | [Respond to security findings](respond-to-security-findings.md) |
| Sentinel probe worker | [Operate Sentinel](operate-sentinel.md#probe-worker-missing) |
| Keycloak unavailable | [Recover SSO](recover-sso.md) |
| Vaultwarden, Homepage, Uptime Kuma unavailable | [Operate self-hosted apps](operate-self-hosted-apps.md) |

Every hand-authored Prometheus rule carries a `runbook_url`. Generated rules from
kube-prometheus-stack and Sloth retain their upstream annotations and are not claimed as
locally authored alert procedures.
