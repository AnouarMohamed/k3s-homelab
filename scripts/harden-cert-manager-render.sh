#!/usr/bin/env bash
set -euo pipefail

# The upstream chart does not expose readiness settings for the controller or
# probe settings for cainjector. Add checks against their chart-defined health
# and metrics ports to satisfy the repository workload contract.
yq eval '
  if .kind == "Deployment" and .metadata.name == "cert-manager" then
    .spec.template.spec.containers |= map(
      if .name == "cert-manager-controller" then
        .readinessProbe = {
          "httpGet": {
            "path": "/livez",
            "port": "http-healthz",
            "scheme": "HTTP"
          },
          "initialDelaySeconds": 5,
          "periodSeconds": 10,
          "timeoutSeconds": 5,
          "failureThreshold": 3
        }
      else . end
    )
  elif .kind == "Deployment" and .metadata.name == "cert-manager-cainjector" then
    .spec.template.spec.containers |= map(
      if .name == "cert-manager-cainjector" then
        .livenessProbe = {
          "tcpSocket": {"port": "http-metrics"},
          "initialDelaySeconds": 10,
          "periodSeconds": 10,
          "timeoutSeconds": 5,
          "failureThreshold": 3
        } |
        .readinessProbe = {
          "tcpSocket": {"port": "http-metrics"},
          "initialDelaySeconds": 5,
          "periodSeconds": 10,
          "timeoutSeconds": 5,
          "failureThreshold": 3
        }
      else . end
    )
  else . end
' -
