# Applications

This directory contains the demo application and self-hosted applications deployed via Argo CD.

Each application follows the structure:
- `base/`: Kustomize base manifests common to all environments
- `overlays/`: Environment-specific overlays (e.g., development, production)

Applications are organized by subdirectories under this directory.