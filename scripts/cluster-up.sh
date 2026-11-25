#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if k3d cluster list | grep -q "^${CLUSTER_NAME} "; then
  echo "Cluster ${CLUSTER_NAME} already exists"
else
  echo "Creating k3d cluster ${CLUSTER_NAME} with registry ${REGISTRY_NAME}:${REGISTRY_PORT}"
  k3d cluster create "${CLUSTER_NAME}" \
    --registry-create "${REGISTRY_NAME}:${REGISTRY_PORT}" \
    --kubeconfig-update-default \
    --kubeconfig-switch-context
fi

kubectl cluster-info
echo "Registry (host push): ${REGISTRY}"
