#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${GITOPS_REPO_URL}" ]]; then
  echo "GITOPS_REPO_URL is required (HTTPS or SSH remote of this gitops repo)" >&2
  exit 1
fi

# Optional private-repo credentials — never commit these
# GITOPS_REPO_USERNAME / GITOPS_REPO_PASSWORD  or  GITOPS_REPO_SSH_PRIVATE_KEY_FILE
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
  echo "No GITOPS_REPO_USERNAME/PASSWORD or GITOPS_REPO_SSH_PRIVATE_KEY_FILE set — assuming public repo"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
for f in "${ROOT_DIR}"/argocd/applications/service-*.yaml; do
  sed "s|GITOPS_REPO_URL_PLACEHOLDER|${GITOPS_REPO_URL}|g" "${f}" > "${tmpdir}/$(basename "${f}")"
done
kubectl apply -f "${tmpdir}"
echo "Applied ArgoCD Applications pointing at ${GITOPS_REPO_URL}"
