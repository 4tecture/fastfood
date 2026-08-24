#!/usr/bin/env bash

FASTFOOD_DOCKER_DEMOS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FASTFOOD_REPO_ROOT="$(cd -- "$FASTFOOD_DOCKER_DEMOS_DIR/../.." && pwd)"
FASTFOOD_SRC_DIR="$FASTFOOD_REPO_ROOT/src"

smoke_finance_image() {
  local image="$1"
  local container="$2"
  local port="$3"

  docker rm --force "$container" >/dev/null 2>&1 || true
  docker run --detach --rm \
    --name "$container" \
    --publish "127.0.0.1:${port}:8080" \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,size=16m \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    --env FeatureManagement__UseInMemoryDatabase=true \
    --env HealthChecks__CheckDapr=false \
    "$image" >/dev/null

  trap 'docker rm --force "'"$container"'" >/dev/null 2>&1 || true' EXIT

  for _ in {1..30}; do
    if curl --fail --silent "http://127.0.0.1:${port}/health/live" >/dev/null; then
      echo "Smoke test passed: $image"
      docker rm --force "$container" >/dev/null
      trap - EXIT
      return 0
    fi
    sleep 0.5
  done

  docker logs "$container" >&2
  return 1
}
