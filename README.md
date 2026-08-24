# FastFood cloud-native training application

FastFood is a .NET 10 microservices training system for containers,
Kubernetes, Dapr, observability, feature flags, and secure CI/CD. It includes
three frontends, Finance, Kitchen, state/workflow-based Order Service, and an
actor workload.

## Local Docker Compose

Prerequisites: Docker Compose, the Smallstep `step` CLI, OpenSSL, and `mkcert`
(run `mkcert -install` once to trust its workstation-local CA).

```bash
cd src
./start-compose.sh -d
docker compose ps
curl --fail http://127.0.0.1:8901/health/ready
```

PowerShell users can run `./start-compose.ps1 -d`. The launchers create a
random local SQL password in ignored `src/.env`, generate ignored Dapr mTLS
certificates when needed, build locked dependencies, and bind published ports to loopback.
The Docker socket is exposed to Traefik only through a read-only API proxy.
Set `FASTFOOD_ROTATE_CERTIFICATES=true` when an intentional local certificate
rotation is required.

The default is the simplified workshop stack: Finance uses its in-memory
database and application/Dapr telemetry exporters are disabled. To run the
complete SQL and observability setup from `main`, enable full mode:

```bash
./start-compose.sh --full -d
# PowerShell: ./start-compose.ps1 --full -d
```

The direct Compose equivalent is:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.full.yml \
  --profile full \
  up --build -d
```

After that one-time certificate bootstrap, the familiar workshop commands work
directly and do not require `--env-file`:

```bash
docker compose up -d
docker compose ps
docker compose down
```

The SQL password is only used by full mode. Set `MSSQL_SA_PASSWORD` to override
the clearly marked local-demo fallback, or use `start-compose.*` once to create
a random `.env` value. Existing `.env.local` files are migrated by the launchers.

Do not use the Compose stack as a production deployment. Its local dashboards,
self-signed certificates, SQL `sa` login, and infrastructure services are
deliberately convenient for a workstation workshop. Use the hardened Helm
charts, managed data services, workload identity, external secret management,
TLS ingress, admission controls, and signed image digests in shared clusters.

## Training paths

- [Docker labs](demos/DockerDemos/01_Basics/index.md)
- [Kubernetes workshop](demos/Kubernetes/README.md)
- [Pipeline labs](demos/Pipelines/HOL/fastfood-templates.md)
- [Feature flags](demos/FeatureFlags/FeatureFlags.md)
- [Observability queries](demos/Observability/ObservabilityDemoQueries.md)

## Quality gates

```bash
cd src
dotnet restore FastFoodDelivery.sln --locked-mode
dotnet build FastFoodDelivery.sln --configuration Release --no-restore
helm lint chart/fastfood --with-subcharts
```

The solution treats compiler warnings as errors, commits NuGet lock files, uses
non-root read-only runtime images, publishes separate live/ready health checks,
and provides resource limits, disruption budgets, network policies, restricted
security contexts, and image-digest support in every service chart. CI publishes
SBOM/provenance plus digest metadata; CD deploys the exact published digests.
