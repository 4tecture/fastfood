---
name: playwright-ui-system-tests-csharp
description: Implement or update FastFood C# Playwright UI system tests with xUnit v3, Page Objects, stable data-testid selectors, observable waits, and multi-tab SignalR workflows. Use for changes under FastFood.Ui.System.Tests or when durable UI regression coverage is required.
---

# Playwright UI System Tests for C#

Use the existing `src/systemtests/FastFood.Ui.System.Tests` framework. Interactive investigation
uses VS Code browser tools; this skill creates committed, repeatable regression tests.

This repository-specific C# workflow is informed by GitHub's current
[awesome-copilot Playwright UI system-test skill](https://github.com/github/awesome-copilot/tree/main/skills/playwright-ui-system-tests)
and the existing FastFood Page Object implementation, retrieved 2026-08-24.

## Prerequisites

1. Inspect `OrderWorkflowTests.cs`, `Helpers/BrowserHelper.cs`, `Base/PlaywrightTestBase.cs`,
   `Configuration/TestConfiguration.cs`, and the relevant Page Objects.
2. With the full stack running, install browsers once with:

```bash
cd src/systemtests/FastFood.Ui.System.Tests
bash ./setup.sh
```

## Architecture rules

- Tests express journeys and assertions only; never access `IPage` directly from a test.
- Page Objects own navigation, locators, parsing, and waits.
- Use `BrowserHelper` to open POS, Kitchen Monitor, and Order Status tabs. Keep all required
  tabs open for SignalR-driven workflows.
- Prefer `data-testid` plus stable `data-*` identity attributes. Text selectors are a last resort.
- Use Playwright web-first waits and observable application state. Do not add `Task.Delay`,
  polling sleeps, or an arbitrary wait after a state-changing action.
- Add a production `data-testid` only when the required state is otherwise unobservable.
- Keep recordings and screenshots under ignored output directories.

## Cart aggregation regression

Only when the work item concerns duplicate-product aggregation, load
[the cart scenario](references/cart-aggregation-scenario.md). The important Page Object contract
is that `AddProductAsync` completes when the requested cart state is observable. A wait based only
on line-count growth is invalid when an existing line may change quantity.

Before editing, compare the acceptance criteria with existing coverage. If the scenario is already
durably covered and the latest changes did not alter selectors, waits, or user-visible behavior,
make no edits and rerun the focused test.

## Validation

`global.json` selects the .NET 10 Microsoft.Testing.Platform runner. Use `--project` and native
xUnit v3 filters; do not use `dotnet test -- --help` or legacy positional-project syntax.

Run the narrowest fully qualified test method first, then the complete UI project when time permits:

```bash
dotnet test \
  --project src/systemtests/FastFood.Ui.System.Tests/FastFood.Ui.System.Tests.csproj \
  --configuration Release --no-restore --no-ansi --zero-tests-policy strict \
  --filter-method "FastFood.Ui.System.Tests.ClassName.MethodName"

dotnet test \
  --project src/systemtests/FastFood.Ui.System.Tests/FastFood.Ui.System.Tests.csproj \
  --configuration Release --no-restore --no-ansi --zero-tests-policy strict
```

For an audience-visible local run, prefix the focused command with `HEADED=1`. If production code
or a production selector changed after the last rebuild, first recreate the full stack with
`docker compose down` and `docker compose up -d --build` from `src`.

Report the command, duration, result, browser artifacts, and any test not run. Never claim a test
passed from source inspection alone.
