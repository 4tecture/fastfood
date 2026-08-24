# Deterministic local verification

Run every command from the repository root unless the block changes directory.

## .NET 10 test runner

`global.json` selects the .NET 10 Microsoft.Testing.Platform runner. Use `--project` and its
native xUnit v3 filters. Do not use legacy positional-project syntax and never probe help with
`dotnet test -- --help`; that invalid separator can terminate the test host. When help is needed:

```bash
dotnet test --project src/services/order/OrderService.Unit.Tests/OrderService.Unit.Tests.csproj --help
```

Run one newly added regression by its fully qualified method name:

```bash
dotnet test \
  --project src/services/order/OrderService.Unit.Tests/OrderService.Unit.Tests.csproj \
  --configuration Release --no-restore --no-ansi --output Normal \
  --filter-method "OrderService.Unit.Tests.Namespace.ClassName.MethodName" \
  --zero-tests-policy strict
```

Run the complete order unit-test project:

```bash
dotnet test \
  --project src/services/order/OrderService.Unit.Tests/OrderService.Unit.Tests.csproj \
  --configuration Release --no-restore --no-ansi --output Normal \
  --zero-tests-policy strict
```

The strict zero-test policy prevents a bad filter from producing a false green. For the solution
build:

```bash
dotnet build src/FastFoodDelivery.sln --configuration Release --no-restore
```

## Full Compose rebuild

After any production-code or runtime-configuration change, recreate the complete topology. Keep
`up` detached so the agent can continue with health checks and browser verification:

```bash
cd src
docker compose down
docker compose up -d --build
docker compose ps
curl --fail http://127.0.0.1:8901/health/ready
cd ..
```

If health fails, inspect `docker compose ps` and relevant logs. Do not claim browser verification
until the readiness check succeeds and the required application URLs load.
