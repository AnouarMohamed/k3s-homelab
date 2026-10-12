#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"

yq eval '
  if .kind == "PodDisruptionBudget" then
    .spec.unhealthyPodEvictionPolicy = "AlwaysAllow"
  else
    .
  end
' -
