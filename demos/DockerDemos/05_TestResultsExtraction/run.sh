#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

BUILD_ID="$(date -u +%Y%m%d%H%M%S)-$$"
FINAL_IMAGE="financeservice-demo-testresultextraction"
RESULTS_DIR="$SCRIPT_DIR/TestResults/$BUILD_ID"

mkdir -p "$RESULTS_DIR"
docker buildx build \
  --file "$SCRIPT_DIR/Dockerfile" \
  --target test-results \
  --output "type=local,dest=$RESULTS_DIR" \
  "$FASTFOOD_SRC_DIR"

find "$RESULTS_DIR" -name '*.trx' -print -quit | grep -q . || { echo "TRX output missing" >&2; exit 1; }
find "$RESULTS_DIR" -name '*.coverage.cobertura.*.xml' -print -quit | grep -q . || { echo "Cobertura output missing" >&2; exit 1; }

docker buildx build --load --tag "$FINAL_IMAGE" --file "$SCRIPT_DIR/Dockerfile" --target final "$FASTFOOD_SRC_DIR"
smoke_finance_image "$FINAL_IMAGE" "demo-test-results" 18088
echo "Test and coverage artifacts: $RESULTS_DIR"
