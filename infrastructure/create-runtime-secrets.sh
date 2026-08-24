#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:?Usage: create-runtime-secrets.sh <namespace>}"
: "${FASTFOOD_REDIS_PASSWORD:?Set FASTFOOD_REDIS_PASSWORD in the current shell}"
: "${FASTFOOD_FINANCE_CONNECTION_STRING:?Set FASTFOOD_FINANCE_CONNECTION_STRING in the current shell}"

if [[ "$FASTFOOD_REDIS_PASSWORD" == *$'\n'* || "$FASTFOOD_REDIS_PASSWORD" == *$'\r'* ||
      "$FASTFOOD_FINANCE_CONNECTION_STRING" == *$'\n'* || "$FASTFOOD_FINANCE_CONNECTION_STRING" == *$'\r'* ]]; then
  echo "Secret values must not contain newline characters." >&2
  exit 1
fi

# Read values through stdin so credentials never appear in kubectl's process
# arguments or in Helm release history.
printf 'redis-password=%s\n' "$FASTFOOD_REDIS_PASSWORD" | kubectl --namespace "$NAMESPACE" create secret generic fastfood-redis \
  --from-env-file=/dev/stdin \
  --dry-run=client --output=yaml | kubectl apply -f -

printf 'ConnectionStrings__FinanceDatabase=%s\n' "$FASTFOOD_FINANCE_CONNECTION_STRING" | kubectl --namespace "$NAMESPACE" create secret generic financeservice-database \
  --from-env-file=/dev/stdin \
  --dry-run=client --output=yaml | kubectl apply -f -

echo "Runtime Secrets reconciled in namespace $NAMESPACE. Values were not stored in Helm."
