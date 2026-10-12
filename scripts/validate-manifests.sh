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
    case "${file}" in
      "${repository_root}/platform/longhorn/"* | \
        "${repository_root}/platform/cloudnative-pg/"* | \
        "${repository_root}/platform/snapshot-controller/"* | \
        "${repository_root}/platform/velero/"* | \
        "${repository_root}/platform/openbao/"* | \
        "${repository_root}/platform/external-secrets/"* | \
        "${repository_root}/platform/runtime-secrets/"* | \
        "${repository_root}/clusters/homelab/bootstrap/runtime-secrets/"* | \
        "${repository_root}/observability/"* | \
        "${repository_root}/policies/"*)
        continue
        ;;
    esac
    if ! grep -q '^apiVersion:' "${file}" || ! grep -q '^kind:' "${file}"; then
      continue
    fi
    if grep -qE '^kind: (Kustomization|Component|Application|ApplicationSet|AppProject|Certificate|ClusterIssuer|ClusterPolicy|Gateway|HTTPRoute|Policy|Cilium|ksops)' "${file}"; then
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
