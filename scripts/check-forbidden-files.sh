#!/usr/bin/env bash
set -euo pipefail

forbidden_pattern='(^|/)(\.env($|\.)|kubeconfig($|\.)|age-.*key|id_(rsa|dsa|ecdsa|ed25519)($|\.)|.*\.(age|key|pem|p12)$|.*\.tfstate($|\.))'
matches="$(git ls-files | grep -E "${forbidden_pattern}" || true)"

if [[ -n "${matches}" ]]; then
  printf 'Forbidden public files are tracked:\n%s\n' "${matches}" >&2
  exit 1
fi

printf 'No forbidden public files are tracked.\n'
