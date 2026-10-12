# Monitoring namespace

This component creates the `monitoring` namespace before the stack. PSA enforcement is
privileged only because node-exporter requires host namespaces and host mounts; audit
and warning remain restricted. Operate it through Argo CD and test it with
`make validate-observability`.
