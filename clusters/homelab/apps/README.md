# Argo CD applications

Purpose-first Application manifests connect the GitLab repository at `main` to the
homelab cluster through `homelab-renderer-v1`. Argo CD and Cilium are self-managed with
the same chart inputs used for bootstrap. The bootstrap-secrets Application adopts the
manually seeded repository credential through KSOPS after the first clone. The
production ApplicationSet discovers only `apps/*/overlays/prod`, uses the hard-coded
`applications` project, and cannot choose a different repository or cluster.
