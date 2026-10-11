#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
schema_cache_dir="${repository_root}/.cache/kubeconform"
manifest_roots=(apps clusters observability platform policies)
manifest_files=()
mkdir -p "${schema_cache_dir}"

for root in "${manifest_roots[@]}"; do
  while IFS= read -r -d '' file; do
    if [[ "${file}" == *.sops.yaml ]]; then
      continue
    fi
    if ! grep -q '^apiVersion:' "${file}" || ! grep -q '^kind:' "${file}"; then
      continue
    fi
    if grep -qE '^kind: (Kustomization|Component|Application|ApplicationSet|AppProject|ClusterPolicy|Policy|Cilium|ksops)' "${file}"; then
      continue
    fi
    manifest_files+=("${file}")
  done < <(find "${repository_root}/${root}" -type f \( -name '*.yaml' -o -name '*.yml' \) -print0 2>/dev/null)
done

if [[ "${#manifest_files[@]}" -eq 0 ]]; then
  printf 'No built-in Kubernetes manifests require validation yet.\n'
  exit 0
fi

kubeconform \
  -strict \
  -summary \
  -cache "${schema_cache_dir}" \
  -kubernetes-version 1.36.5 \
  "${manifest_files[@]}"

kube-linter lint "${manifest_files[@]}"
