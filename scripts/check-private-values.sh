#!/usr/bin/env bash
set -euo pipefail

pattern='(^|[^0-9])(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})([^0-9]|$)'
matches="$(git grep -nE "${pattern}" -- ':!config/homelab.yaml' || true)"

if [[ -n "${matches}" ]]; then
  printf 'Private addresses found outside config/homelab.yaml:\n%s\n' "${matches}" >&2
  exit 1
fi

domain="$(awk '$1 == "domain:" {print $2; exit}' config/homelab.yaml | tr -d "\"'")"
if [[ -n "${domain}" && "${domain}" != CHANGE_ME_* ]]; then
  domain_matches="$(git grep -nF "${domain}" -- ':!config/homelab.yaml' || true)"
  if [[ -n "${domain_matches}" ]]; then
    printf 'Configured domain found outside config/homelab.yaml:\n%s\n' \
      "${domain_matches}" >&2
    exit 1
  fi
fi

printf 'No private addresses or configured domain exist outside config/homelab.yaml.\n'
