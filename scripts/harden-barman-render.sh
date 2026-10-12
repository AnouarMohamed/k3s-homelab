#!/usr/bin/env bash
set -euo pipefail

yq eval-all '
  if .kind == "Deployment" and .metadata.name == "barman-cloud-plugin-barman-cloud" then
    .spec.template.spec.containers[] |= (
      select(.name == "barman-cloud") |
      .ports += [{"name": "health", "containerPort": 8081, "protocol": "TCP"}]
    )
  else . end
' -
