# Kubernetes workshop

This workshop takes the same Finance service used by the container labs and
runs it on a local, disposable `kind` cluster. It deliberately uses the
in-memory database and disables Dapr so the first Kubernetes exercises remain
focused. The full application and Dapr are introduced after the core workload
concepts are understood.

## Prerequisites

- Docker
- `kubectl`
- Helm
- `kind`
- .NET and container images can be downloaded from the internet

## 1. Build, load and deploy

```bash
./setup.sh
kubectl --namespace fastfood-training get pods,services
helm --namespace fastfood-training test financeservice
```

The setup script creates a namespace enforcing the Restricted Pod Security
Standard, builds the application image, loads it into kind, validates the Helm
chart, performs an atomic deployment and waits for readiness.

## 2. Configuration and Secrets

Inspect the rendered configuration without sending it to a cluster:

```bash
helm template financeservice ../../src/services/finance/FinanceService/chart/financeservice \
  --namespace fastfood-training --values values.training.yaml
```

Production values use a credential-free Azure workload-identity connection
string. If a training variation needs a password-bearing connection string,
create `financeservice-database` out of band with
`../../infrastructure/create-runtime-secrets.sh`, set `database.existingSecret`,
and keep the value out of Helm release history.

## 3. Probes and self-healing

```bash
kubectl --namespace fastfood-training describe pod -l app.kubernetes.io/name=financeservice
kubectl --namespace fastfood-training delete pod -l app.kubernetes.io/name=financeservice --wait=false
kubectl --namespace fastfood-training rollout status deployment/financeservice
```

Compare `/health/live`, `/health/ready` and the startup probe. Liveness never
checks external dependencies; readiness does.

## 4. Resources, scheduling and scaling

```bash
kubectl --namespace fastfood-training top pods
kubectl --namespace fastfood-training get hpa
kubectl --namespace fastfood-training get poddisruptionbudget
```

Enable autoscaling only when metrics-server is installed. Discuss how CPU HPA
depends on requests and why Dapr sidecar requests are also declared.

## 5. Security and network policy

```bash
kubectl --namespace fastfood-training auth can-i --list \
  --as=system:serviceaccount:fastfood-training:financeservice
kubectl --namespace fastfood-training get networkpolicy -o yaml
kubectl --namespace fastfood-training get pod -o jsonpath='{range .items[*]}{.spec.containers[*].securityContext}{"\n"}{end}'
```

The application runs non-root with a read-only root filesystem, RuntimeDefault
seccomp, no added capabilities, no privilege escalation, and no automatically
mounted API token.

## 6. Rollouts and rollback

```bash
kubectl --namespace fastfood-training set image deployment/financeservice \
  financeservice=fastfood/financeservice:does-not-exist
kubectl --namespace fastfood-training rollout status deployment/financeservice --timeout=30s || true
kubectl --namespace fastfood-training rollout undo deployment/financeservice
```

## 7. Dapr and observability

Install Dapr in a separate module, set `dapr.io/enabled: "true"`, remove
`HealthChecks__CheckDapr=false`, and verify that readiness uses Dapr's outbound
health endpoint. Continue with `../Observability/ObservabilityDemoQueries.md`.

## Cleanup

```bash
./cleanup.sh
```
