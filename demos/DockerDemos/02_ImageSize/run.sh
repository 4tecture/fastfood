#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"
IMAGE_NAME_BASE="financeservice-demo-imagesize"

for target in base_standard base_alpine base_chiseled base_chiseled_extra; do
  suffix="${target#base_}"
  docker build --tag "${IMAGE_NAME_BASE}-${suffix//_/-}" --file "$SCRIPT_DIR/Dockerfile" --target "$target" "$FASTFOOD_SRC_DIR"
done

docker image ls --format '{{.Repository}}\t{{.Size}}' | sort | grep "$IMAGE_NAME_BASE"
smoke_finance_image "${IMAGE_NAME_BASE}-chiseled-extra" "demo-image-size" 18085
