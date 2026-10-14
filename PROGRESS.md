# Progress

Observed results only are recorded here. Expected AWS and cluster behavior remains in
the runbooks and verification checklist until it is observed.

## Current work

Temporary AWS validation and observability evidence preparation are in progress. No AWS
resource has been created. The canonical repository architecture remains the three-PC
k3s cluster; AWS is a short-lived substitute for tests that do not depend on LAN ARP or
L2 broadcast behavior.

## Observed repository validation

| Date | Command | Real output summary |
| --- | --- | --- |
| 2026-10-14 | `make ansible-templates` | Passed 5 tasks; both k3s and kube-vip templates parsed and all assertions passed. |
| 2026-10-14 | `make ansible-syntax` | Parsed `site.yaml`, `upgrade.yaml`, and `reset.yaml` without syntax errors. |
| 2026-10-14 | `make validate-observability` | Helm lint passed for 7 charts; kubeconform and kube-linter reported no invalid resources; promtool accepted 10 alert rules and all dashboard PromQL; deterministic rendering matched. |
| 2026-10-14 | `make validate-aws-validation` | OpenTofu reused pinned AWS provider 6.68.0 and reported the configuration valid. No account was accessed. |
| 2026-10-14 | `make aws-validation-tools` | Checksum verification passed and Session Manager plugin 1.2.814.0 was installed under `.tools/bin`. |
| 2026-10-14 | `make lint` | Markdown and Ansible lint passed; tracked SOPS documents produced configured yamllint warnings only. |
| 2026-10-14 | `make validate` | All repository validators completed successfully, including deterministic chart rendering, kubeconform, kube-linter, Kyverno's 10 policy tests, promtool, Sentinel unit tests, GHCR package policy, and OpenTofu validation. |
| 2026-10-14 | `make security` | Gitleaks found no leaks in the working tree or across all 49 commits. |

## Defects repaired during this work

- The former cluster dashboard exposed only two inventory totals. It is now an
  operator-first overview with live user impact, delivery, resource pressure, network,
  database, backup, and control-plane signals.
- Longhorn 1.12 robustness uses the `state` label. The earlier numeric comparison could
  miss degraded volumes; the alert and dashboards now query `degraded` and `faulted`
  label states.
- Dashboard validation previously assumed each JSON value occupied one YAML line. It
  now accepts readable multiline JSON and syntax-checks every PromQL expression.
- The k3s playbook now waits for the shared API endpoint from the initial server, which
  works for both a LAN VIP and an internal validation load balancer.
- The pinned K3s source uses a credential chain that includes the EC2 IAM provider.
  The AWS inventory can therefore omit persistent S3 access keys while retaining a
  narrowly scoped instance role; the S3 region and 28-snapshot remote retention are
  now explicit.
- The Cilium bootstrap can omit LB IPAM and L2 announcements only for AWS validation,
  where VPC networking cannot reproduce LAN broadcast behavior. Canonical installs
  still enable and validate both resources.

## Not done

- AWS authentication, account plan, apply, bootstrap, tests, and destruction have not
  run.
- No dashboard has been opened against live telemetry.
- No screenshot has been captured.
- kube-vip ARP and Cilium L2 announcement behavior cannot be proven in AWS and remain
  pending broadcast-capable hardware.
- The seven-day telemetry storage-growth observation has not started.
