#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scan_root="$(mktemp -d)"
trap 'rm -rf "${scan_root}"' EXIT

while IFS= read -r -d '' path; do
  [[ -f "${repository_root}/${path}" ]] || continue
  install -D -m 0600 "${repository_root}/${path}" "${scan_root}/${path}"
done < <(git -C "${repository_root}" ls-files --cached --others --exclude-standard -z)

gitleaks dir --redact --verbose "${scan_root}"
gitleaks git --redact --verbose --log-opts=--all "${repository_root}"
