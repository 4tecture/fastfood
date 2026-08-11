#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib.sh"
IMAGE_NAME="financeservice-demo-hardening"
docker build --tag "$IMAGE_NAME" --file "$SCRIPT_DIR/Dockerfile" "$FASTFOOD_SRC_DIR"
smoke_finance_image "$IMAGE_NAME" "demo-hardening" 18086
docker image inspect "$IMAGE_NAME" --format 'Configured user: {{.Config.User}}'
