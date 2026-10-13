# Policy tests

The pinned Kyverno CLI applies five CEL workload policies to one compliant and one
deliberately non-compliant Pod. Expected pass and failure outcomes cover labels,
resources, probes, container hardening, and immutable image references.

Registry and signature policies are schema-validated offline; cryptographic verification
requires the signed Sentinel image and remains a hardware/registry acceptance check.
