# Alertmanager runtime secret

This component gives a dedicated monitoring service account a bounded OpenBao role,
materializes only the notification webhook, and configures Alertmanager routing. Put
the value in OpenBao as documented in `HUMAN_TODO.md`; validate manifests without a
secret value using `make validate-observability`.
