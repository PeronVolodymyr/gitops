#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

SERVICE="${1:-}"
TAG="${2:-}"

if [[ -z "${SERVICE}" || -z "${TAG}" ]]; then
  echo "Usage: $0 <service-a|service-b> <immutable-tag>" >&2
  exit 1
fi

KUSTOMIZATION="${ROOT_DIR}/apps/${SERVICE}/overlays/local/kustomization.yaml"
if [[ ! -f "${KUSTOMIZATION}" ]]; then
  echo "Missing ${KUSTOMIZATION}" >&2
  exit 1
fi

# Update newTag under images for this service (BSD/macOS and GNU sed)
if sed --version >/dev/null 2>&1; then
  sed -i -E "/name: ${SERVICE}/,/newTag:/ s|newTag: .*|newTag: \"${TAG}\"|" "${KUSTOMIZATION}"
else
  sed -i '' -E "/name: ${SERVICE}/,/newTag:/ s|newTag: .*|newTag: \"${TAG}\"|" "${KUSTOMIZATION}"
fi

echo "Updated ${KUSTOMIZATION} -> ${SERVICE}:${TAG}"
echo "Commit and push this change so ArgoCD can sync the new immutable tag."
