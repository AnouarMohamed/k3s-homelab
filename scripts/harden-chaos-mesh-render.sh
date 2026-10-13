#!/usr/bin/env bash
set -euo pipefail

yq eval-all '
  if .kind == "Deployment" and .metadata.name == "chaos-controller-manager" then
    .spec.template.metadata.annotations.rollme = "NORMALIZED" |
    .spec.template.spec.containers[0].securityContext = {
      "allowPrivilegeEscalation": false,
      "capabilities": {"drop": ["ALL"]},
      "readOnlyRootFilesystem": true,
      "runAsNonRoot": true,
      "seccompProfile": {"type": "RuntimeDefault"}
    } |
    .spec.template.spec.containers[0].readinessProbe = {
      "tcpSocket": {"port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 10
    } |
    .spec.template.spec.containers[0].livenessProbe = {
      "tcpSocket": {"port": "http"}, "initialDelaySeconds": 15, "periodSeconds": 20
    }
  elif .kind == "DaemonSet" and .metadata.name == "chaos-daemon" then
    .spec.template.spec.containers[0].readinessProbe = {
      "tcpSocket": {"port": "grpc"}, "initialDelaySeconds": 5, "periodSeconds": 10
    } |
    .spec.template.spec.containers[0].livenessProbe = {
      "tcpSocket": {"port": "grpc"}, "initialDelaySeconds": 15, "periodSeconds": 20
    }
  else . end
' -
