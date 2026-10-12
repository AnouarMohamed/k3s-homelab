# Argo CD notification secret

This component gives Argo CD a separate bounded OpenBao identity and materializes its
notification webhook. The notification controller configuration remains in the pinned
Argo CD chart values. Operate it through Argo CD and validate it with
`make validate-observability`.
