# Uptime Kuma

Uptime Kuma provides private interactive monitoring through the internal Gateway. Its
rootless image stores state on Longhorn, and the cluster-wide Velero schedule covers
the namespace. Sentinel remains the by design limited public status page.

Argo CD deploys `overlays/prod`. Validate with `make validate-identity-apps`.
