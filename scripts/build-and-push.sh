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

case "${SERVICE}" in
  service-a) SRC="${SERVICE_A_DIR}" ;;
  service-b) SRC="${SERVICE_B_DIR}" ;;
  *) echo "Unknown service: ${SERVICE}" >&2; exit 1 ;;
esac

if [[ ! -d "${SRC}" ]]; then
  echo "Service directory not found: ${SRC}" >&2
  exit 1
fi

IMAGE="${REGISTRY}/${SERVICE}:${TAG}"

echo "Building ${SERVICE} (JVM) in ${SRC}"
(
  cd "${SRC}"
  ./mvnw -q package -DskipTests
  docker build -f src/main/docker/Dockerfile.jvm -t "${IMAGE}" .
)

echo "Pushing ${IMAGE}"
docker push "${IMAGE}"
echo "Pushed ${IMAGE}"
