#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="financeservice-demo-scan"

docker scout cves --only-severity critical,high --exit-code "$IMAGE_NAME"
