#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
config_file="${repository_root}/config/homelab.yaml"

placeholders="$(yq '.. | select(tag == "!!str") | select(test("^CHANGE_ME_"))' "${config_file}")"
if [[ -n "${placeholders}" ]]; then
  printf 'Central configuration still contains CHANGE_ME values. See HUMAN_TODO.md.\n' >&2
  exit 1
fi

invalid_interfaces="$(
  yq --unwrapScalar '.spec.network.nodes[].interface' "${config_file}" | \
    grep -Ev '^[A-Za-z0-9_.:-]+$' || true
)"
if [[ -n "${invalid_interfaces}" ]]; then
  printf 'Node interface names contain unsupported regex characters:\n%s\n' \
    "${invalid_interfaces}" >&2
  exit 1
fi

printf 'Central configuration contains no placeholders.\n'
