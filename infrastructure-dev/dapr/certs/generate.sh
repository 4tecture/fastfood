#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="${FASTFOOD_CERT_DIR:-$SCRIPT_DIR/generated}"
umask 077

mkdir -p "$CERT_DIR"

command -v step >/dev/null 2>&1 || {
  echo "The step CLI is required: https://smallstep.com/docs/step-cli/installation/" >&2
  exit 1
}

step certificate create cluster.local "$CERT_DIR/ca.crt" "$CERT_DIR/ca.key" \
  --profile root-ca --no-password --insecure --force
step certificate create cluster.local "$CERT_DIR/issuer.crt" "$CERT_DIR/issuer.key" \
  --ca "$CERT_DIR/ca.crt" --ca-key "$CERT_DIR/ca.key" \
  --profile intermediate-ca --not-after 8760h --no-password --insecure --force

escape_pem() {
  awk '{ printf "%s\\n", $0 }' "$1"
}

{
  printf 'DAPR_TRUST_ANCHORS="%s"\n' "$(escape_pem "$CERT_DIR/ca.crt")"
  printf 'DAPR_CERT_CHAIN="%s"\n' "$(escape_pem "$CERT_DIR/issuer.crt")"
  printf 'DAPR_CERT_KEY="%s"\n' "$(escape_pem "$CERT_DIR/issuer.key")"
  printf 'NAMESPACE=fastfood\n'
} > "$CERT_DIR/mtls.env"

chmod 600 "$CERT_DIR"/*.key "$CERT_DIR/mtls.env"
echo "Generated local-only Dapr certificates in $CERT_DIR"
