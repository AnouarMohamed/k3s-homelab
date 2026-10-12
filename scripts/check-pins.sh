#!/usr/bin/env bash
set -euo pipefail

patterns=(
  'image:[[:space:]]*[^[:space:]]+:latest([[:space:]]|$)'
  'targetRevision:[[:space:]]*(HEAD|master)([[:space:]]|$)'
  "@latest([[:space:]\"']|$)"
)

failed=0
for pattern in "${patterns[@]}"; do
  matches="$(git grep -nE "${pattern}" -- '*.yaml' '*.yml' '*.json' 'Dockerfile*' 'scripts/*' \
    ':!policies/tests/resources/invalid-pod.yaml' || true)"
  if [[ -n "${matches}" ]]; then
    printf 'Unpinned dependency reference:\n%s\n' "${matches}" >&2
    failed=1
  fi
done

image_matches="$(
  git grep -nE '(^|[[:space:]])image:[[:space:]]*[^[:space:]]+' -- \
    '*.yaml' '*.yml' ':!platform/snapshot-controller/upstream/**' \
    ':!policies/tests/resources/invalid-pod.yaml' | \
    grep -v '@sha256:[a-f0-9]\{64\}' | \
    grep -vE 'image:[[:space:]]*\$\{[A-Z0-9_]+_IMAGE\}' || true
)"
if [[ -n "${image_matches}" ]]; then
  printf 'Container image is not pinned by digest:\n%s\n' "${image_matches}" >&2
  failed=1
fi

image_variables="$(
  git grep -hE 'image:[[:space:]]*\$\{[A-Z0-9_]+_IMAGE\}' -- '*.yaml' '*.yml' | \
    sed -E 's/.*\$\{([A-Z0-9_]+_IMAGE)\}.*/\1/' | sort -u || true
)"
while IFS= read -r image_variable; do
  [[ -z "${image_variable}" ]] && continue
  if ! git grep -qE "^${image_variable}=[^[:space:]]+@sha256:[a-f0-9]{64}$" -- '*.env'; then
    printf 'Rendered image variable lacks a digest-pinned dependency: %s\n' \
      "${image_variable}" >&2
    failed=1
  fi
done <<<"${image_variables}"

dockerfile_matches="$(
  git grep -nE '^FROM[[:space:]]+[^[:space:]]+' -- 'Dockerfile*' | \
    grep -v '@sha256:[a-f0-9]\{64\}' || true
)"
if [[ -n "${dockerfile_matches}" ]]; then
  printf 'Dockerfile base image is not pinned by digest:\n%s\n' \
    "${dockerfile_matches}" >&2
  failed=1
fi

exit "${failed}"
