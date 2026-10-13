#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"

required_files=(
  README.md LICENSE CODEOWNERS SECURITY.md docs/architecture.md docs/compatibility.md
  docs/evidence.md docs/skills-demonstrated.md docs/adr/README.md docs/runbooks/README.md
  docs/img/README.md docs/experimental-phone-workers.md
)
for file in "${required_files[@]}"; do
  test -s "${repository_root}/${file}"
done

test "$(wc -l <"${repository_root}/README.md")" -lt 150
test "$(grep -c '^```mermaid$' "${repository_root}/docs/architecture.md")" -ge 6
test ! -e "${repository_root}/CONTRIBUTING.md"
test -z "$(find "${repository_root}" \
  \( -path '*/.git' -o -path '*/.cache' -o -path '*/.tools' \) -prune -o \
  -iname '*pull_request_template*' -print -quit)"

mapfile -t adr_numbers < <(find "${repository_root}/docs/adr" -maxdepth 1 -type f \
  -name '[0-9][0-9][0-9][0-9]-*.md' -printf '%f\n' | cut -d- -f1 | sort)
test "${#adr_numbers[@]}" = "$(printf '%s\n' "${adr_numbers[@]}" | sort -u | wc -l)"

mapfile -t alert_files < <(rg -l '^\s*- alert:' "${repository_root}/apps" \
  "${repository_root}/observability" "${repository_root}/platform" \
  "${repository_root}/policies" --glob '*.yaml')
test "$(yq eval-all '[.spec.groups[]?.rules[]? | select(has("alert") and (.annotations.runbook_url == null))] | length' "${alert_files[@]}")" = 0

help_output="$(make help)"
for target in help tools lint validate security bootstrap-nodes upgrade-k3s reset \
  bootstrap-cni bootstrap-gitops bootstrap-platform test tofu-plan \
  validate-chaos-dr validate-identity-apps validate-portfolio; do
  grep -qE "^  ${target}[[:space:]]" <<<"${help_output}"
done

grep -q 'HOMELAB_CACHE_ROOT=/tmp/homelab-cache' \
  "${repository_root}/platform/argocd/configure-argocd.yaml"
grep -q 'docker.io/curlimages/curl:8.16.0@sha256:' \
  "${repository_root}/platform/argocd/configure-argocd.yaml"
for phase in 2 3 4 5 6 7 8 9 11; do
  grep -q 'HOMELAB_CACHE_ROOT' \
    "${repository_root}/scripts/fetch-phase${phase}-dependencies.sh"
done

printf 'Phase 12 portfolio, evidence, governance, and operations indexes validated.\n'
