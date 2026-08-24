#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib.sh"
IMAGE_NAME="financeservice-demo-buildandrun"
docker build --tag "$IMAGE_NAME" --file "$SCRIPT_DIR/Dockerfile" "$FASTFOOD_SRC_DIR"
smoke_finance_image "$IMAGE_NAME" "demo-build-run" 18082
