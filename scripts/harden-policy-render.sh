#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"

yq eval '
  if .kind == "Job" then
    .spec.ttlSecondsAfterFinished = 300
  elif .kind == "Deployment" and (
    .metadata.name == "kyverno-background-controller" or
    .metadata.name == "kyverno-reports-controller"
  ) then
    .spec.template.spec.containers |= map(
      .livenessProbe = {
        "tcpSocket": {"port": "metrics"},
        "initialDelaySeconds": 15,
        "periodSeconds": 30,
        "timeoutSeconds": 5,
        "failureThreshold": 3
      } |
      .readinessProbe = {
        "tcpSocket": {"port": "metrics"},
        "initialDelaySeconds": 5,
        "periodSeconds": 10,
        "timeoutSeconds": 3,
        "failureThreshold": 3
      }
    )
  else
    .
  end
' -
