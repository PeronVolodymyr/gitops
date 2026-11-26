#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

# Must match spec.source.repoURL in argocd/applications/*.yaml
GITOPS_REPO_URL="${GITOPS_REPO_URL:-https://github.com/PeronVolodymyr/gitops.git}"

# Optional private-repo credentials — never commit these
if [[ -n "${GITOPS_REPO_SSH_PRIVATE_KEY_FILE:-}" ]]; then
  kubectl -n "${ARGOCD_NAMESPACE}" create secret generic gitops-repo \
    --from-literal=type=git \
    --from-literal=url="${GITOPS_REPO_URL}" \
    --from-file=sshPrivateKey="${GITOPS_REPO_SSH_PRIVATE_KEY_FILE}" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n "${ARGOCD_NAMESPACE}" label secret gitops-repo argocd.argoproj.io/secret-type=repository --overwrite
elif [[ -n "${GITOPS_REPO_USERNAME:-}" && -n "${GITOPS_REPO_PASSWORD:-}" ]]; then
  kubectl -n "${ARGOCD_NAMESPACE}" create secret generic gitops-repo \
    --from-literal=type=git \
    --from-literal=url="${GITOPS_REPO_URL}" \
    --from-literal=username="${GITOPS_REPO_USERNAME}" \
    --from-literal=password="${GITOPS_REPO_PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n "${ARGOCD_NAMESPACE}" label secret gitops-repo argocd.argoproj.io/secret-type=repository --overwrite
else
  echo "Assuming public repo at ${GITOPS_REPO_URL}"
fi

kubectl apply -f "${ROOT_DIR}/argocd/applications/service-a.yaml"
kubectl apply -f "${ROOT_DIR}/argocd/applications/service-b.yaml"
echo "Applied ArgoCD Applications from ${ROOT_DIR}/argocd/applications/"
