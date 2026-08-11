#!/usr/bin/env bash
set -euo pipefail

TARGET_NAMESPACE="${1:-}"
DEPLOYMENT_USER='system:serviceaccount:cicd:deployment-sa'
EXPECTED_CONTEXT="${FASTFOOD_KUBERNETES_CONTEXT:-dev-aks-k8sdemo-westeurope-admin}"
CURRENT_CONTEXT="$(kubectl config current-context)"

if [[ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]]; then
  echo "Refusing to test RBAC in kubectl context '$CURRENT_CONTEXT'." >&2
  echo "Expected '$EXPECTED_CONTEXT'. Switch context or set FASTFOOD_KUBERNETES_CONTEXT explicitly." >&2
  exit 2
fi

if [[ ! "$TARGET_NAMESPACE" =~ ^pr-[1-9][0-9]*$ ]]; then
  echo "Usage: $0 pr-<positive-id>" >&2
  echo "Pass an existing PR namespace after running create-deployment-sa.sh." >&2
  exit 2
fi

kubectl get namespace "$TARGET_NAMESPACE" >/dev/null

assert_can() {
  local expected="$1"
  shift
  local actual
  # kubectl returns exit code 1 for the expected "no" answer. Capture the
  # output without allowing errexit to stop the negative authorization tests.
  actual="$(kubectl auth can-i "$@" --as="$DEPLOYMENT_USER" || true)"
  if [[ "$actual" != "$expected" ]]; then
    echo "Expected '$expected' for: kubectl auth can-i $*; got '$actual'." >&2
    exit 1
  fi
  echo "PASS [$expected] kubectl auth can-i $*"
}

assert_can yes create deployments --namespace "$TARGET_NAMESPACE"
assert_can yes create secrets --namespace "$TARGET_NAMESPACE"
assert_can no create deployments --namespace default
assert_can no create clusterroles.rbac.authorization.k8s.io
assert_can no create pods/exec --namespace "$TARGET_NAMESPACE"

# RBAC must allow namespace creation for the PR lifecycle, while admission
# narrows the names. Server-side dry runs exercise both layers without storing
# either namespace.
kubectl create namespace pr-2147483647 --dry-run=client --output=yaml \
  | kubectl label --local --filename=- --output=yaml \
      fastfood.dev/environment=pull-request \
      fastfood.dev/pull-request-id=2147483647 \
      fastfood.dev/redis-db=13 \
  | kubectl apply --as="$DEPLOYMENT_USER" --dry-run=server --filename=- >/dev/null
echo "PASS [admission allow] namespace/pr-2147483647"

if kubectl create namespace fastfood-rbac-guardrail-test \
    --as="$DEPLOYMENT_USER" \
    --dry-run=server \
    --output=name >/dev/null 2>&1; then
  echo "Admission guardrail allowed a non-PR namespace." >&2
  exit 1
fi
echo "PASS [admission deny] namespace/fastfood-rbac-guardrail-test"

if kubectl create namespace pr-2147483646 --dry-run=client --output=yaml \
    | kubectl label --local --filename=- --output=yaml \
        fastfood.dev/environment=pull-request \
        fastfood.dev/pull-request-id=2147483646 \
        fastfood.dev/redis-db=13 \
    | kubectl apply --as="$DEPLOYMENT_USER" --dry-run=server --filename=- >/dev/null 2>&1; then
  echo "Admission guardrail allowed an incorrect Redis DB assignment." >&2
  exit 1
fi
echo "PASS [admission deny] incorrect deterministic Redis DB assignment"

kubectl create rolebinding fastfood-release-manager \
  --namespace "$TARGET_NAMESPACE" \
  --clusterrole fastfood-release-manager \
  --serviceaccount cicd:deployment-sa \
  --dry-run=client \
  --output=yaml \
  | kubectl apply --as="$DEPLOYMENT_USER" --dry-run=server --filename=- >/dev/null
echo "PASS [admission allow] approved release RoleBinding"

if kubectl create rolebinding fastfood-rbac-guardrail-test \
    --namespace "$TARGET_NAMESPACE" \
    --clusterrole fastfood-release-manager \
    --serviceaccount cicd:deployment-sa \
    --dry-run=client \
    --output=yaml \
    | kubectl apply --as="$DEPLOYMENT_USER" --dry-run=server --filename=- >/dev/null 2>&1; then
  echo "Admission guardrail allowed an unapproved ClusterRole binding." >&2
  exit 1
fi
echo "PASS [admission deny] unapproved ClusterRole binding"

echo "Deployment RBAC verification succeeded."
