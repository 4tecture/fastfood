#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

command -v trivy >/dev/null 2>&1 || { echo "Install Trivy before running this lab." >&2; exit 1; }
IMAGE_NAME="financeservice-demo-scan"
VULN_OUTPUT="$SCRIPT_DIR/trivy_vuln_report.json"
SBOM_OUTPUT="$SCRIPT_DIR/trivy_sbom.spdx.json"

docker build --tag "$IMAGE_NAME" --file "$SCRIPT_DIR/Dockerfile" "$FASTFOOD_SRC_DIR"
trivy image --severity HIGH,CRITICAL --ignore-unfixed --format json --output "$VULN_OUTPUT" "$IMAGE_NAME"
trivy image --format spdx-json --output "$SBOM_OUTPUT" "$IMAGE_NAME"
trivy config --severity HIGH,CRITICAL --exit-code 1 "$SCRIPT_DIR"
trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$IMAGE_NAME"

echo "Reports written to $VULN_OUTPUT and $SBOM_OUTPUT"
