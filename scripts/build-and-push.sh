#!/usr/bin/env bash
# Delegates Maven package + docker build/push to the application repository.
# Image build ownership lives in service-a / service-b; this repo only orchestrates.
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

case "${SERVICE}" in
  service-a) SRC="${SERVICE_A_DIR}" ;;
  service-b) SRC="${SERVICE_B_DIR}" ;;
  *) echo "Unknown service: ${SERVICE}" >&2; exit 1 ;;
esac

BUILD_SCRIPT="${SRC}/scripts/build-and-push.sh"
if [[ ! -x "${BUILD_SCRIPT}" && ! -f "${BUILD_SCRIPT}" ]]; then
  echo "Missing ${BUILD_SCRIPT} — each app repo owns package/image build." >&2
  exit 1
fi

echo "Delegating image build to ${SRC} (TAG=${TAG}, REGISTRY=${REGISTRY})"
REGISTRY="${REGISTRY}" "${BUILD_SCRIPT}" "${TAG}"
