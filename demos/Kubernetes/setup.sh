#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CLUSTER_NAME="fastfood-training"
NAMESPACE="fastfood-training"
CHART="$REPO_ROOT/src/services/finance/FinanceService/chart/financeservice"

for tool in docker kind kubectl helm; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing prerequisite: $tool" >&2; exit 1; }
done

if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-config.yaml"
fi

docker build --tag fastfood/financeservice:training \
  --file "$REPO_ROOT/src/services/finance/FinanceService/Dockerfile" "$REPO_ROOT/src"
kind load docker-image fastfood/financeservice:training --name "$CLUSTER_NAME"

kubectl create namespace "$NAMESPACE" --dry-run=client --output=yaml | kubectl apply -f -
kubectl label namespace "$NAMESPACE" \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted --overwrite

helm lint "$CHART" --values "$SCRIPT_DIR/values.training.yaml"

HELM_VERSION="$(helm version --short)"
if [[ ! "$HELM_VERSION" =~ ^v?([0-9]+) ]]; then
  echo "Unable to parse Helm version: $HELM_VERSION" >&2
  exit 1
fi

case "${BASH_REMATCH[1]}" in
  3)
    HELM_SAFETY_ARGS=(--atomic --wait --wait-for-jobs)
    ;;
  4)
    HELM_SAFETY_ARGS=(--rollback-on-failure --wait=legacy --wait-for-jobs)
    ;;
  *)
    echo "Unsupported Helm version: $HELM_VERSION" >&2
    exit 1
    ;;
esac

helm upgrade --install financeservice "$CHART" \
  --namespace "$NAMESPACE" \
  --values "$SCRIPT_DIR/values.training.yaml" \
  "${HELM_SAFETY_ARGS[@]}" --timeout 5m
helm test financeservice --namespace "$NAMESPACE" --logs
