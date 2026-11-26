#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

# Public repo URL is hardcoded in argocd/applications/*.yaml
kubectl apply -f "${ROOT_DIR}/argocd/applications/service-a.yaml"
kubectl apply -f "${ROOT_DIR}/argocd/applications/service-b.yaml"
echo "Applied ArgoCD Applications from ${ROOT_DIR}/argocd/applications/"
