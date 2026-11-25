#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if k3d cluster list | grep -q "^${CLUSTER_NAME} "; then
  k3d cluster delete "${CLUSTER_NAME}"
  echo "Deleted cluster ${CLUSTER_NAME}"
else
  echo "Cluster ${CLUSTER_NAME} not found"
fi
