# Platform Components

This directory contains manifests for platform-level components installed via Argo CD, such as:

- cilium (in kube-system namespace)
- cert-manager
- longhorn
- openbao
- external-secrets-operator

Each component should have its own subdirectory with Kustomize bases and overlays as needed.