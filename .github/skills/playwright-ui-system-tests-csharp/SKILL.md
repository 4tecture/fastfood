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

1. Confirm `npx` is available before suggesting Playwright CLI fallback commands.
2. Inspect `OrderWorkflowTests.cs`, `Helpers/BrowserHelper.cs`, `Base/PlaywrightTestBase.cs`,
   `Configuration/TestConfiguration.cs`, and the relevant Page Objects.
3. With the full stack running, install browsers once with:

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

Load [the cart scenario](references/cart-aggregation-scenario.md) for the duplicate-product
defect. The important Page Object contract is that `AddProductAsync` completes when the requested
cart state is observable. A wait based only on line-count growth is invalid when an existing line
may change quantity.

## Validation

Run the narrowest filter first, then the complete UI project when time permits:

```bash
dotnet test src/systemtests/FastFood.Ui.System.Tests/FastFood.Ui.System.Tests.csproj \
  --filter "FullyQualifiedName~Cart"

dotnet test src/systemtests/FastFood.Ui.System.Tests/FastFood.Ui.System.Tests.csproj
```

Report the command, duration, result, browser artifacts, and any test not run. Never claim a test
passed from source inspection alone.
