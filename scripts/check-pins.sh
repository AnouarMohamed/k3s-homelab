#!/usr/bin/env bash
set -euo pipefail

patterns=(
  'image:[[:space:]]*[^[:space:]]+:latest([[:space:]]|$)'
  'targetRevision:[[:space:]]*(HEAD|master)([[:space:]]|$)'
  "@latest([[:space:]\"']|$)"
)

failed=0
for pattern in "${patterns[@]}"; do
  matches="$(git grep -nE "${pattern}" -- '*.yaml' '*.yml' '*.json' 'Dockerfile*' 'scripts/*' || true)"
  if [[ -n "${matches}" ]]; then
    printf 'Unpinned dependency reference:\n%s\n' "${matches}" >&2
    failed=1
  fi
done

image_matches="$(
  git grep -nE '(^|[[:space:]])image:[[:space:]]*[^[:space:]]+' -- '*.yaml' '*.yml' | \
    grep -v '@sha256:[a-f0-9]\{64\}' || true
)"
if [[ -n "${image_matches}" ]]; then
  printf 'Container image is not pinned by digest:\n%s\n' "${image_matches}" >&2
  failed=1
fi

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
