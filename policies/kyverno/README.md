# Kyverno

Kyverno provides highly available admission, background, cleanup, and reporting
controllers. The chart is checksum verified, every image is digest pinned, and metrics
are scraped by Prometheus. The policy set is deployed in Audit mode first; follow the
promotion runbook before switching the GitOps application to the Deny overlay.

Run `make validate-policy` to lint and render the chart and test the policies.
