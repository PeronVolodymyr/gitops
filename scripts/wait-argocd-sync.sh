#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

for app in service-a service-b; do
  echo "Waiting for Application/${app} to become Synced+Healthy..."
  for _ in $(seq 1 60); do
    sync=$(kubectl -n "${ARGOCD_NAMESPACE}" get application "${app}" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Missing")
    health=$(kubectl -n "${ARGOCD_NAMESPACE}" get application "${app}" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Missing")
    if [[ "${sync}" == "Synced" && "${health}" == "Healthy" ]]; then
      echo "${app}: Synced / Healthy"
      break
    fi
    sleep 5
  done
  sync=$(kubectl -n "${ARGOCD_NAMESPACE}" get application "${app}" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Missing")
  health=$(kubectl -n "${ARGOCD_NAMESPACE}" get application "${app}" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Missing")
  if [[ "${sync}" != "Synced" || "${health}" != "Healthy" ]]; then
    echo "${app} not ready: sync=${sync} health=${health}" >&2
    kubectl -n "${ARGOCD_NAMESPACE}" get application "${app}" -o yaml >&2 || true
    exit 1
  fi
done
