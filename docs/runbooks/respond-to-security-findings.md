# Respond to security findings

## Critical container vulnerability detected

1. Open the Security posture dashboard and identify the namespace, workload, image
   digest, and report name.
2. Inspect the source report without copying it into an issue containing secrets:

   ```bash
   kubectl -n CHANGE_ME_NAMESPACE get vulnerabilityreports
   kubectl -n CHANGE_ME_NAMESPACE describe vulnerabilityreport CHANGE_ME_REPORT
   ```

3. Confirm whether a fixed version exists. Rebuild the owned image from the pinned
   dependency or update the third-party image digest through a reviewed change.
4. Re-run CI scanning and deploy through GitOps. Do not waive `CRITICAL` findings solely
   to make the alert green.
5. Record any accepted risk, affected digest, owner, expiry, and compensating control in
   the incident or decision record.
