# Promote policy enforcement

Use this only after the Audit policy reports are clean for every namespace labeled
`policy.homelab.dev/profile: application`.

1. Confirm the policy controllers and reports are healthy:

   ```bash
   kubectl -n kyverno get deploy,pods
   kubectl get validatingpolicies.policies.kyverno.io
   kubectl get clusterpolicyreports.wgpolicyk8s.io
   ```

2. List Audit failures and either fix the workload or add a narrowly documented
   exception to `docs/security/policy-exceptions.md`. Do not exempt a whole application
   namespace.
3. Render and test the Deny overlay offline:

   ```bash
   scripts/render-gitops.sh policies/standards/enforce >/tmp/policies-enforce.yaml
   make validate-policy
   ```

4. Change the `workload-standards` Argo CD Application path from
   `policies/standards/audit` to `policies/standards/enforce`, open a reviewed merge
   request, and synchronize it during a maintenance window.
5. Submit one known-invalid Pod in a disposable namespace with the application profile;
   expect admission denial. Delete the namespace afterward.

Rollback by restoring the Audit path and synchronizing Argo CD. This changes admission
behavior only; it does not delete existing workloads.
