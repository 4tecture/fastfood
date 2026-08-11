#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

IMAGE_NAME="financeservice-demo-secretsinbuild"
SECRET_FILE="${NUGET_CONFIG_FILE:-$SCRIPT_DIR/secretnugetcredentials.config}"
test -f "$SECRET_FILE" || { echo "NuGet configuration not found: $SECRET_FILE" >&2; exit 1; }

docker build --tag "$IMAGE_NAME" --file "$SCRIPT_DIR/Dockerfile" --target final \
  --secret "id=nugetconfig,src=$SECRET_FILE" "$FASTFOOD_SRC_DIR"

if docker history --no-trunc "$IMAGE_NAME" | grep -F '/run/secrets/nugetconfig' | grep -F 'COPY'; then
  echo "The secret appears to have been copied into a layer." >&2
  exit 1
fi

smoke_finance_image "$IMAGE_NAME" "demo-build-secret" 18089
echo "Build secret was mounted for restore and was not copied into the final image."
