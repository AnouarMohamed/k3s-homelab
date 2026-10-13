# Vaultwarden

Vaultwarden provides an internal password-vault service. It uses CloudNativePG,
Longhorn for attachments, OpenBao-delivered credentials, and CNPG object-store
backups. Registration and its administration endpoint are disabled by default.

Argo CD deploys `overlays/prod`. Validate with `make validate-identity-apps`; operate
it with the Identity and apps application runbook.
