# FastFood repository instructions

FastFood is a .NET 10 and Vue 3 microservices training application. Dapr provides
service invocation, state, pub/sub, actors, and workflows. Treat the repository as
a production-shaped demo: make the smallest correct change, preserve public HTTP
and event contracts, and verify behavior with evidence.

## Architecture

The local topology is illustrated in [the architecture overview](../docs/overview.drawio.png).

- `OrderService` owns order APIs and supports three interchangeable processing patterns:
  `OrderProcessingServiceState`, `OrderProcessingServiceActor`, and
  `OrderProcessingServiceWorkflow` plus its workflow activities.
- `OrderService.Actors` hosts the Dapr actor implementation.
- `KitchenService` consumes order events and manages preparation.
- `FinanceService` handles payment operations.
- The POS, Kitchen Monitor, and Customer Order Status frontends are Vue SPAs.
- RabbitMQ provides pub/sub, Redis provides state, and Traefik routes the local HTTPS hosts.

When shared order behavior changes, identify every active implementation of the
contract and either update all applicable implementations or explain why one is
not affected. Never assume that the default implementation is the only one.

## Local development

Run commands from the repository root unless a command explicitly changes directory.

```bash
# Full local stack
cd src && bash ./start-compose.sh -d
docker compose ps
curl --fail http://127.0.0.1:8901/health/ready

# Solution build
dotnet restore src/FastFoodDelivery.sln --locked-mode
dotnet build src/FastFoodDelivery.sln --configuration Release --no-restore

# Focused order unit tests
dotnet test --project src/services/order/OrderService.Unit.Tests/OrderService.Unit.Tests.csproj \
  --configuration Release --no-restore --zero-tests-policy strict

# C# Playwright UI system tests (requires the running stack)
cd src/systemtests/FastFood.Ui.System.Tests
bash ./setup.sh
cd ../../..
dotnet test --project src/systemtests/FastFood.Ui.System.Tests/FastFood.Ui.System.Tests.csproj \
  --configuration Release --no-restore --zero-tests-policy strict
```

`global.json` selects .NET 10 Microsoft.Testing.Platform. Use `dotnet test --project ...` and
never use the legacy `dotnet test -- --help` probe. Detailed filtering and full Compose rebuild
commands live in the task-specific bugfix and Playwright skills.

Local applications:

- POS: `https://pos.localtest.me/`
- Kitchen: `https://kitchen.localtest.me/`
- Order status: `https://orderstatus.localtest.me/`
- Dapr dashboard: `https://daprdashboard.localtest.me/`
- Grafana: `https://grafana.localtest.me/`
- Jaeger: `https://jaeger.localtest.me/jaeger/ui/`

## Change and review rules

- Read the relevant implementation, adjacent tests, and shared contracts before editing.
- Prefer regression-first fixes and targeted verification before broad test runs.
- Preserve Dapr state keys, event names, serialization shapes, routes, and status semantics
  unless the task explicitly authorizes a contract change.
- Keep UI automation details in page objects; tests express user behavior and assertions.
- Do not use fixed delays when an observable state or Playwright web-first wait is available.
- Do not commit credentials, generated certificates, browser recordings, screenshots, or
  local `.env` files.
- Review in this order: correctness, consistency across order implementations, state/event
  compatibility, regression evidence, security, then scope and maintainability.
- Report commands executed and their outcomes. Do not claim verification that was not run.
