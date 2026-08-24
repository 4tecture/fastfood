#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_ENV="$SCRIPT_DIR/.env"
LEGACY_LOCAL_ENV="$SCRIPT_DIR/.env.local"
CERT_GENERATOR="$SCRIPT_DIR/../infrastructure-dev/dapr/certs/generate.sh"
PROXY_CERT_GENERATOR="$SCRIPT_DIR/../infrastructure-dev/proxy/certs/generate.sh"
FULL_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.full.yml"

FULL_MODE=false
PASSTHROUGH_ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--full" ]; then
    FULL_MODE=true
  else
    PASSTHROUGH_ARGS+=("$arg")
  fi
done

for tool in docker openssl step mkcert; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Missing prerequisite: $tool" >&2
    exit 1
  }
done

if [ ! -f "$LOCAL_ENV" ]; then
  umask 077
  if [ -f "$LEGACY_LOCAL_ENV" ]; then
    cp "$LEGACY_LOCAL_ENV" "$LOCAL_ENV"
    echo "Migrated local Compose secrets from .env.local to .env"
  else
    FASTFOOD_RANDOM_PASSWORD="FastFood-$(openssl rand -hex 24)!A"
    printf 'MSSQL_SA_PASSWORD=%s\n' "$FASTFOOD_RANDOM_PASSWORD" > "$LOCAL_ENV"
    echo "Created local-only Compose secrets in $LOCAL_ENV"
  fi
  chmod 600 "$LOCAL_ENV"
fi

FASTFOOD_CERT_DIR="$SCRIPT_DIR/../infrastructure-dev/dapr/certs/generated"
if [ "${FASTFOOD_ROTATE_CERTIFICATES:-false}" = "true" ] ||
   [ ! -s "$FASTFOOD_CERT_DIR/ca.crt" ] ||
   [ ! -s "$FASTFOOD_CERT_DIR/ca.key" ] ||
   [ ! -s "$FASTFOOD_CERT_DIR/issuer.crt" ] ||
   [ ! -s "$FASTFOOD_CERT_DIR/issuer.key" ] ||
   [ ! -s "$FASTFOOD_CERT_DIR/mtls.env" ]; then
  FASTFOOD_CERT_DIR="$FASTFOOD_CERT_DIR" "$CERT_GENERATOR"
else
  echo "Using existing local Dapr certificates. Set FASTFOOD_ROTATE_CERTIFICATES=true to rotate them."
fi

FASTFOOD_PROXY_CERT_DIR="$SCRIPT_DIR/../infrastructure-dev/proxy/certs"
if [ "${FASTFOOD_ROTATE_CERTIFICATES:-false}" = "true" ] ||
   [ ! -s "$FASTFOOD_PROXY_CERT_DIR/_wildcard.localtest.me.pem" ] ||
   [ ! -s "$FASTFOOD_PROXY_CERT_DIR/_wildcard.localtest.me-key.pem" ]; then
  "$PROXY_CERT_GENERATOR"
else
  echo "Using existing local Traefik certificate."
fi

COMPOSE_ARGS=(
  --env-file "$LOCAL_ENV"
  --file "$SCRIPT_DIR/docker-compose.yml"
)
if [ "$FULL_MODE" = "true" ]; then
  COMPOSE_ARGS+=(--file "$FULL_COMPOSE_FILE" --profile full)
  echo "Starting the full stack (SQL and observability enabled)."
else
  echo "Starting the simplified HOL stack. Use --full for SQL and observability."
fi

docker compose "${COMPOSE_ARGS[@]}" up --build "${PASSTHROUGH_ARGS[@]}"
