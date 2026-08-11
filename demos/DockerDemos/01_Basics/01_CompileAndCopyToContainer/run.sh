#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib.sh"

PUBLISH_DIR="$SCRIPT_DIR/publish"
IMAGE_NAME="financeservice-demo-compileandcopy"
rm -rf "$PUBLISH_DIR"
dotnet publish "$FASTFOOD_SRC_DIR/services/finance/FinanceService/FinanceService.csproj" -c Release -o "$PUBLISH_DIR"
docker build --tag "$IMAGE_NAME" --file "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"
smoke_finance_image "$IMAGE_NAME" "demo-compile-copy" 18081
