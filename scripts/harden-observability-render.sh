#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
export PATH="${repository_root}/.tools/bin:${PATH}"

yq eval '
  if .kind == "PodDisruptionBudget" then
    .spec.unhealthyPodEvictionPolicy = "AlwaysAllow"
  elif .kind == "Deployment" and .metadata.name == "monitoring-grafana" then
    .spec.template.spec.containers |= map(
      if .name == "grafana-sc-dashboard" then
        .ports = ((.ports // []) + [{
          "name": "sidecar-health",
          "containerPort": 8080,
          "protocol": "TCP"
        }])
      else
        .
      end
    )
  elif .kind == "Deployment" and .metadata.name == "sloth" then
    .spec.template.spec.containers |= map(
      if .name == "sloth" then
        .livenessProbe = {
          "tcpSocket": {"port": "metrics"},
          "initialDelaySeconds": 10,
          "periodSeconds": 20,
          "timeoutSeconds": 3
        } |
        .readinessProbe = {
          "tcpSocket": {"port": "metrics"},
          "initialDelaySeconds": 5,
          "periodSeconds": 10,
          "timeoutSeconds": 3
        }
      else
        .
      end
    )
  elif .kind == "ClusterRole" and .metadata.name == "sloth" then
    .rules = [
      {
        "apiGroups": ["sloth.slok.dev"],
        "resources": ["prometheusservicelevels"],
        "verbs": ["list", "watch"]
      },
      {
        "apiGroups": ["sloth.slok.dev"],
        "resources": ["prometheusservicelevels/status"],
        "verbs": ["update"]
      },
      {
        "apiGroups": ["monitoring.coreos.com"],
        "resources": ["prometheusrules"],
        "verbs": ["create", "get", "update"]
      }
    ]
  else
    .
  end
' -
