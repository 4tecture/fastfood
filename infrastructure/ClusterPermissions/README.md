# Deployment identity and PR environments

The FastFood pipelines use one deployment ServiceAccount, but its authorization
is split into two deliberately small capabilities:

1. `fastfood-release-manager` defines the resources Helm may manage. It is a
   reusable ClusterRole with **no cluster-wide binding**. A RoleBinding grants
   it in one namespace at a time.
2. `fastfood-pr-environment-manager` lets the identity create, update, and
   delete namespaces and install the release RoleBinding. Native admission
   policies restrict those operations to namespaces named `pr-<positive id>`
   and to the exact approved ClusterRole binding.

This preserves the existing Azure DevOps Kubernetes service connection while
removing the previous unrestricted `verbs: ["*"]` ClusterRoleBinding.

## Install or migrate

Run the bootstrap script once with an administrator context. With no arguments,
it preflights and authorizes the demo cluster's `staging` and `prod` namespaces:

```bash
kubectl config use-context dev-aks-k8sdemo-westeurope-admin
./create-deployment-sa.sh
```

Both scripts refuse to operate on a different context by default. For a fork
using another cluster, set `FASTFOOD_KUBERNETES_CONTEXT` to the intended current
context explicitly.

Alternatively, pass every long-lived release namespace explicitly:

```bash
./create-deployment-sa.sh staging prod
```

The script applies the ServiceAccount, reusable release ClusterRole, PR
lifecycle role and admission policies, then deletes the legacy
`deployment-manager` / `deployment-sa-binding` grant if present. It does not
recreate a permanent `kubernetes.io/service-account-token` Secret.

The target cluster must serve `ValidatingAdmissionPolicy`. The script uses the
stable `admissionregistration.k8s.io/v1` API on Kubernetes 1.30+ and adapts the
same manifest to `v1beta1` on Kubernetes 1.28-1.29. The current PR demo cluster
serves the stable API. The script fails closed if neither API is available; do not install the PR
lifecycle ClusterRoleBinding without the guardrail policies.

For another static namespace later, create the namespace as an administrator
and apply only the namespaced binding:

```bash
kubectl create namespace staging
kubectl apply --namespace staging -f deployment-rolebinding.yml
```

PR pipelines apply that same binding idempotently after creating `pr-<id>`.
The admission policy prevents the deployment identity from using its namespace
lifecycle permission for `default`, `production`, or any other namespace.
It also requires the pipeline-managed PR, environment, and Redis database
labels. The release identity can list namespaces only so the bootstrap can
reject a Redis database assignment that is already in use.

The Redis database is calculated during pipeline execution as
`(pullRequestId % 13) + 3`, reserving databases 0-2 and using 3-15 for PRs.
The current shared Redis deployment therefore has 13 PR slots. PR IDs with the
same remainder map to the same slot; the bootstrap rejects that collision
instead of mixing their data. Cleanup deletes the namespace and releases the
slot. Dapr additionally prefixes state keys and consumer IDs with the
Kubernetes namespace.

After the first PR environment exists, verify both the allowed and denied paths
with server-side dry runs (the test stores no additional namespaces):

```bash
./verify-deployment-rbac.sh pr-123
```

## Authentication

Production pipelines should use Azure workload identity federation. Permanent
ServiceAccount token Secrets are intentionally not created. A time-limited
token is convenient for a workshop-day Kubernetes service connection:

```bash
kubectl --namespace cicd create token deployment-sa --duration=8h
```

The API server may shorten the requested lifetime. Check the token expiration
and rotate it before the demo. The migration script intentionally does not
delete an existing `cicd/deployment-sa-token` Secret because doing so would
silently break a service connection that still uses it; it prints a warning.
After migrating that connection, revoke the legacy credential explicitly:

```bash
kubectl delete secret deployment-sa-token --namespace cicd
```

The pipeline identity can manage Helm release Secrets inside an authorized
namespace; treat it as a privileged namespace identity and protect deployment
environments. The runtime ServiceAccounts receive none of these permissions.

Helm `--wait` follows a Deployment through its ReplicaSet to its Pods. The
release identity therefore has `get`, `list`, and `watch` access to Pods and
ReplicaSets, but cannot create, update, patch, or delete either controller-owned
resource directly.

The role also contains a temporary, non-effective rule for the unserved API
group `core`. Finance chart 1.0.1 used that spelling in its `k8s-wait-for`
Role; Kubernetes's RBAC anti-escalation check otherwise prevents Helm from
reproducing the latest stable chart. Remove the compatibility rule after
`main` publishes the modern finance chart, which no longer creates that Role.

Managing Services, Ingresses, and NetworkPolicies can redirect or broaden
traffic. Those permissions are unavoidable for this chart-owning release
identity. Namespace-local Role and RoleBinding management is included for
charts that create runtime RBAC; Kubernetes's built-in bind and escalation
checks prevent those charts from granting permissions the release identity does
not already possess.
