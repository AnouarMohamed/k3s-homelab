# GitOps bootstrap

This directory holds the minimum declarative state needed to hand control to the root
application. `kustomization.yaml` contains only restricted projects, component
Applications, and the hard-coded ApplicationSet. The separate
`repository-credentials` Kustomization lets the bootstrap-secrets Application adopt
the initially seeded credential through KSOPS after Argo CD can clone the repository.

The checked-in repository-credential Secret is valid SOPS ciphertext containing only
placeholder strings. It uses the disposable public recipient in `.sops.yaml`; the
corresponding private identity is by design not committed, so this fixture cannot
be mistaken for usable credentials.

Before GitOps bootstrap, I replaces the recipient in `.sops.yaml`, creates a
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
printing decrypted values. `make bootstrap-gitops` refuses the disposable recipient,
checks that `SOPS_AGE_KEY_FILE` matches the configured recipient, injects the GitLab URL
from `config/homelab.yaml` in memory, and never writes decrypted content to disk.
