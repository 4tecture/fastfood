#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_CONTEXT="${FASTFOOD_KUBERNETES_CONTEXT:-dev-aks-k8sdemo-westeurope-admin}"
CURRENT_CONTEXT="$(kubectl config current-context)"
if [[ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]]; then
  echo "Refusing to change RBAC in kubectl context '$CURRENT_CONTEXT'." >&2
  echo "Expected '$EXPECTED_CONTEXT'. Switch context or set FASTFOOD_KUBERNETES_CONTEXT explicitly." >&2
  exit 2
fi

if (( $# == 0 )); then
  TARGET_NAMESPACES=(staging prod)
else
  TARGET_NAMESPACES=("$@")
fi

# Validate every target before changing the live authorization model. This
# avoids revoking the legacy binding and only then discovering a typo.
for target_namespace in "${TARGET_NAMESPACES[@]}"; do
  kubectl get namespace "$target_namespace" >/dev/null
done

# Cluster bootstrap. Run this script with an administrator context; the
# deployment identity cannot grant these permissions to itself.
kubectl apply -f "$SCRIPT_DIR/deployment-sa.yml"
kubectl apply -f "$SCRIPT_DIR/deployment-clusterrole.yml"

# Install the explicit grants before revoking the legacy binding, keeping the
# migration available to in-flight staging and production deployments.
for target_namespace in "${TARGET_NAMESPACES[@]}"; do
  kubectl apply --namespace "$target_namespace" -f "$SCRIPT_DIR/deployment-rolebinding.yml"
done

# Install the guardrails before granting namespace lifecycle permissions. If
# the cluster does not support ValidatingAdmissionPolicy, the new lifecycle
# binding is never created and the script exits before touching the old grant.
kubectl apply -f "$SCRIPT_DIR/pr-environment-manager-clusterrole.yml"
if kubectl get --raw /apis/admissionregistration.k8s.io/v1 2>/dev/null \
    | grep -q '"name":"validatingadmissionpolicies"'; then
  kubectl apply -f "$SCRIPT_DIR/pr-environment-guardrails.yml"
elif kubectl get --raw /apis/admissionregistration.k8s.io/v1beta1 2>/dev/null \
    | grep -q '"name":"validatingadmissionpolicies"'; then
  # ValidatingAdmissionPolicy was beta in Kubernetes 1.28-1.29. Its schema is
  # compatible with this manifest; only the served API version differs.
  sed 's#^apiVersion: admissionregistration.k8s.io/v1$#apiVersion: admissionregistration.k8s.io/v1beta1#' \
    "$SCRIPT_DIR/pr-environment-guardrails.yml" | kubectl apply -f -
else
  echo "The cluster does not serve the ValidatingAdmissionPolicy API." >&2
  echo "PR lifecycle permissions were not granted." >&2
  exit 1
fi
kubectl apply -f "$SCRIPT_DIR/pr-environment-manager-clusterrolebinding.yml"

# All replacement grants are now active. Remove the pre-hardening,
# unrestricted cluster-wide authorization. The ServiceAccount and its
# credential remain in place, so existing service connections keep working.
kubectl delete clusterrolebinding deployment-sa-binding --ignore-not-found
kubectl delete clusterrole deployment-manager --ignore-not-found

echo
echo "FastFood deployment RBAC installed."
echo "  Static release namespaces: ${TARGET_NAMESPACES[*]}"
echo "  Dynamic namespaces:       pr-<positive pull-request id> only"
echo
echo "The existing Azure DevOps service connection can keep using deployment-sa."
echo "For a short-lived workshop token (8 hours):"
echo "  kubectl --namespace cicd create token deployment-sa --duration=8h"
echo "Use workload identity federation for long-lived CI/CD authentication."

if kubectl get secret deployment-sa-token --namespace cicd >/dev/null 2>&1; then
  echo
  echo "WARNING: legacy permanent token Secret cicd/deployment-sa-token still exists."
  echo "It was not deleted because an existing service connection may use it."
  echo "After migrating that connection, revoke it explicitly with:"
  echo "  kubectl delete secret deployment-sa-token --namespace cicd"
fi
