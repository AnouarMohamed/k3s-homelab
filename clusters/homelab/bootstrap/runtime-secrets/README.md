# Runtime-secret prerequisites

This bootstrap creates only the restricted OpenBao and External Secrets namespaces and
an internal cert-manager CA/server certificate. Private keys are generated inside the
cluster and never rendered into Git. The CA is dedicated to OpenBao transport; it is
not a public or general-purpose homelab issuer.

Argo CD applies the annotated issuer and certificate waves before the OpenBao chart.
Certificate readiness and renewal remain hardware checks.
