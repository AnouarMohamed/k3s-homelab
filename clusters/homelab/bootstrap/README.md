# GitOps bootstrap

This directory holds the minimum declarative state needed to install Argo CD and hand
control to the root application. Phase 3 implements and validates that boundary.

The checked-in repository-credential Secret is valid SOPS ciphertext containing only
placeholder strings. It uses the disposable public recipient in `.sops.yaml`; the
corresponding private identity is intentionally not committed, so this fixture cannot
be mistaken for usable credentials.

Before Phase 3 bootstrap, Anouar replaces the recipient in `.sops.yaml`, creates a
scratch plaintext Secret containing the real least-privilege GitLab deploy credentials,
and encrypts it directly to the tracked path:

```bash
sops encrypt \
  --encrypted-regex '^(data|stringData)$' \
  --output clusters/homelab/bootstrap/provide-gitlab-repository-credentials.sops.yaml \
  /secure/scratch/provide-gitlab-repository-credentials.yaml
```

The scratch plaintext file must remain outside this repository and be removed securely
after encryption. Validate the resulting metadata with `sops filestatus` without
printing decrypted values.
