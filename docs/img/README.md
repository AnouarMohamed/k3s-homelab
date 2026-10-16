# Evidence capture checklist

Screenshots are evidence only when they come from the running validation environment.
Keep the browser at 1920 by 1080, retain the visible Grafana or application time range,
and capture enough surrounding interface to identify the product. Redact account IDs,
public addresses, tokens, usernames, and notification destinations before committing.

| File | Required view | Status |
| --- | --- | --- |
| `argocd-application-tree.png` | Root application tree with health and sync state | CAPTURED AWS 2026-10-16 |
| `grafana-operations-overview.png` | Current impact and change/delivery sections | CAPTURED AWS 2026-10-16 |
| `hubble-service-map.png` | Selected application traffic and policy verdicts | CAPTURED AWS 2026-10-16 |
| `sentinel-status-page.png` | Public-safe selected service status | CAPTURED AWS 2026-10-16 |
| `argo-rollouts-canary.png` | Canary steps, analysis, and stable revision | CAPTURED AWS 2026-10-16 |
| `dr-restore-result.png` | Completed restore object plus source evidence | PENDING HUMAN DR DRILL |

Before committing an image:

1. Confirm its state can be reproduced with a command in the bring-up checklist.
2. Check the full frame for secrets, public addresses, browser profiles, and account IDs.
3. Record the capture time and corresponding test in `PROGRESS.md`.
4. Run `sha256sum docs/img/*.png` and record the digest with the evidence entry.
5. Keep failed tests as logs or incident notes, not as misleading “healthy” screenshots.

No placeholder or generated screenshots are accepted.
