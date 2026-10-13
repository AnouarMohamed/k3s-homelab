# Security posture summary

The platform uses layered controls rather than treating one scanner as a boundary.

- Pod Security Admission sets a minimum namespace baseline.
- Kyverno audits application labels, resources, probes, container hardening, immutable
  images, approved registries, matching NetworkPolicies, and GitLab OIDC signatures.
- The Audit overlay is the deployed starting state. Deny mode is a reviewed promotion,
  not an untested flag flip.
- Trivy Operator continuously creates vulnerability, SBOM, configuration, and RBAC
  reports. Node collection is disabled to avoid unnecessary host access.
- CI scans source and images before promotion; Sentinel connects signing and digest-based
  delivery to the admission rule.
- Infrastructure exceptions are specific, limited, and separate from application policy.

Runtime report freshness, admission latency, signature verification, and finding counts
remain `not run yet` until I complete the Policy and supply chain verification checklist.
