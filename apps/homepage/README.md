# Homepage

Homepage is an internal, read-only service directory. Its links and layout are stored
as ConfigMaps; it receives no Kubernetes API token and no application credentials.

Argo CD deploys `overlays/prod`. Validate with `make validate-identity-apps`.
