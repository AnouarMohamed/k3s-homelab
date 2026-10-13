#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"
workflow="${repository_root}/.github/workflows/publish-ghcr-packages.yaml"

yq '.' "${workflow}" >/dev/null

expected_packages=$'homepage\nkeycloak\nsentinel\nuptime-kuma\nvaultwarden\nwhoami'
actual_packages="$(yq --unwrapScalar \
  '.jobs.publish-deployment-packages.strategy.matrix.include[].package' \
  "${workflow}" | sort)"
test "${actual_packages}" = "${expected_packages}"

while IFS=$'\t' read -r package path; do
  test -n "${package}"
  test -d "${repository_root}/${path}"
  test -f "${repository_root}/${path}/README.md"
done < <(yq --unwrapScalar \
  '.jobs.publish-deployment-packages.strategy.matrix.include[] | [.package, .path] | @tsv' \
  "${workflow}")

test "$(yq '[.jobs.publish-deployment-packages.steps[] | select(has("uses")) | .uses | select(test("@[a-f0-9]{40}$") | not)] | length' "${workflow}")" = 0
test "$(yq '.permissions.packages' "${workflow}")" = write
test "$(yq '.permissions."id-token"' "${workflow}")" = write
grep -q 'sha256sum --check --strict' "${workflow}"
grep -q 'cosign sign --yes' "${workflow}"
grep -q 'oras copy.*main' "${workflow}"

printf 'Six digest-addressable, keylessly signed GHCR deployment packages validated.\n'
