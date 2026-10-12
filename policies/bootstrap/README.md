# Policy bootstrap

These namespaces isolate Kyverno and Trivy Operator and apply Kubernetes 1.36
restricted Pod Security Admission labels. Deploy this before either controller chart.
Validate it with `make validate-policy`.
