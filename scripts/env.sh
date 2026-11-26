#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-quarkus-demo}"
REGISTRY_NAME="${REGISTRY_NAME:-k3d-quarkus-registry.localhost}"
REGISTRY_PORT="${REGISTRY_PORT:-5001}"
REGISTRY="${REGISTRY_NAME}:${REGISTRY_PORT}"
NAMESPACE="${NAMESPACE:-demo}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

# Absolute paths assuming sibling layout: IdeaProjects/{gitops,service-a,service-b}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
SERVICE_A_DIR="${SERVICE_A_DIR:-${PARENT_DIR}/service-a}"
SERVICE_B_DIR="${SERVICE_B_DIR:-${PARENT_DIR}/service-b}"
