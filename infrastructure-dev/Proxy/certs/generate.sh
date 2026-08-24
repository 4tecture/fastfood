#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
umask 077

command -v mkcert >/dev/null 2>&1 || {
  echo "mkcert is required: https://github.com/FiloSottile/mkcert" >&2
  exit 1
}

mkcert \
  -cert-file "$SCRIPT_DIR/_wildcard.localtest.me.pem" \
  -key-file "$SCRIPT_DIR/_wildcard.localtest.me-key.pem" \
  '*.localtest.me'
chmod 600 "$SCRIPT_DIR/_wildcard.localtest.me-key.pem"
echo "Generated local-only Traefik TLS material in $SCRIPT_DIR"
