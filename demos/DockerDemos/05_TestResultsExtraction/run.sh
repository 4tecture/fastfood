#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

BUILD_ID="$(date -u +%Y%m%d%H%M%S)-$$"
TEST_IMAGE="financeservice-demo-tests:$BUILD_ID"
FINAL_IMAGE="financeservice-demo-testresultextraction"
RESULTS_DIR="$SCRIPT_DIR/TestResults/$BUILD_ID"
CONTAINER_NAME="test-results-$BUILD_ID"

docker build --tag "$TEST_IMAGE" --file "$SCRIPT_DIR/Dockerfile" --build-arg BUILDID="$BUILD_ID" --target test "$FASTFOOD_SRC_DIR"
mkdir -p "$RESULTS_DIR"
docker create --name "$CONTAINER_NAME" "$TEST_IMAGE" >/dev/null
trap 'docker rm --force "'"$CONTAINER_NAME"'" >/dev/null 2>&1 || true' EXIT
docker cp "$CONTAINER_NAME:/testresults/." "$RESULTS_DIR"
docker rm "$CONTAINER_NAME" >/dev/null
trap - EXIT

find "$RESULTS_DIR" -name '*.trx' -print -quit | grep -q . || { echo "TRX output missing" >&2; exit 1; }
find "$RESULTS_DIR" -name 'coverage.cobertura.xml' -print -quit | grep -q . || { echo "Cobertura output missing" >&2; exit 1; }

docker build --tag "$FINAL_IMAGE" --file "$SCRIPT_DIR/Dockerfile" --target final "$FASTFOOD_SRC_DIR"
smoke_finance_image "$FINAL_IMAGE" "demo-test-results" 18088
echo "Test and coverage artifacts: $RESULTS_DIR"
