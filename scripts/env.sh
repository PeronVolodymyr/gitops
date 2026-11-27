#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-quarkus-demo}"
REGISTRY_NAME="${REGISTRY_NAME:-k3d-quarkus-registry.localhost}"
REGISTRY_PORT="${REGISTRY_PORT:-5001}"
REGISTRY="${REGISTRY_NAME}:${REGISTRY_PORT}"
NAMESPACE="${NAMESPACE:-demo}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
