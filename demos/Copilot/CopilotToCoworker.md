# From Co-Pilot to Co-Worker: live demo runbook

This runbook prepares and recovers the GitHub Copilot coworker demo. The live path uses
Azure DevOps; replace `tracker=azure-devops` with `tracker=github` to exercise the alternate
reporting skill.

The copy-ready live prompt sets `demo-run=true`. This skips duplicate detection for repeat
presentations and marks the new work item as demo-generated. Omit that setting only when
rehearsing the normal bounded duplicate policy.

## Before the audience arrives

Run these downloads/builds before the session; do not spend stage time installing dependencies.

```bash
git switch demo-coworkers
git status --short --branch

cd src
docker compose pull --ignore-buildable
bash ./start-compose.sh -d
docker compose ps
curl --fail http://127.0.0.1:8901/health/ready

cd systemtests/FastFood.Ui.System.Tests
bash ./setup.sh
cd ../../../
```

Confirm these pages load:

- `https://pos.localtest.me/`
- `https://kitchen.localtest.me/`
- `https://orderstatus.localtest.me/`
- `https://daprdashboard.localtest.me/`
- `https://grafana.localtest.me/`
- `https://jaeger.localtest.me/jaeger/ui/`

In VS Code:

1. Open **Chat: Configure Tools** and authenticate the `azure-devops` and `github` MCP servers.
2. Confirm **Built-in > Browser** tools are enabled.
3. Open Chat **Diagnostics** and confirm all five agents, six skills, three instruction files,
   and `.github/copilot-instructions.md` load without errors.
4. Confirm at least one configured fallback model is available for every agent.
5. Keep the Source Control view visible so the audience can see when the working tree changes.

Read-only external checks:

```bash
az boards query \
  --organization https://dev.azure.com/4tecture-demo \
  --project k8sDemo \
  --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = 'k8sDemo' ORDER BY [System.ChangedDate] DESC" \
  --query "[0].id" --output tsv

gh auth status
```

The hosted GitHub MCP server uses its own OAuth connection. If `gh auth status` fails, run
`gh auth login -h github.com` before choosing `tracker=github`, because `gh api` is the documented
write fallback when the connected GitHub MCP toolset is read-only.

## Demo 1: delegate the investigation

Select **Defect Investigator** and paste only:

```text
We received customer feedback that quantities in the shopping cart sometimes behave
incorrectly when the same product is added repeatedly.

Investigate the issue in the running application. Reproduce it, determine the actual and
expected behavior, and, if it is a genuine defect, create a professional work item with
reproducible steps, acceptance criteria, and screenshot evidence.

tracker=azure-devops
demo-run=true
Do not modify the application.
```

Human review checkpoint:

- The behavior was reproduced twice from a fresh cart.
- The screenshot exists under `output/playwright/` and contains no sensitive data.
- Observations and hypotheses are clearly separated.
- Demo mode skipped duplicate detection and the Bug has the `copilot-demo` tag.
- The Bug contains steps, expected/actual behavior, impact, prominent labeled analysis, and
  acceptance criteria.
- The clearest screenshot is both attached and rendered inline in the reproduction steps.
- `git status --short` is empty.

Open the Bug URL and briefly review it. Then click **Review and hand off to developer**. The
handoff is prefilled but deliberately not submitted; review it before sending.

## Demo 2: delegate the repair

The **Bugfix Developer** should:

1. Read the Bug and evidence.
2. Derive a concise symptom slug from the Bug title and create
   `bugfix/{work-item-id}-{symptom-slug}` from `demo-coworkers`.
3. Add and run a unit regression that fails before production changes.
4. Discover every applicable order-processing implementation.
5. Implement the smallest compatible change.
6. Run targeted tests/builds and repeat the browser journey.

Human review checkpoint:

```bash
git status --short --branch
review_merge_base="$(git merge-base demo-coworkers HEAD)"
git diff --stat "$review_merge_base"
git diff --check "$review_merge_base"
```

Require the agent to show both failing-before and passing-after evidence. Confirm it did not
push or create a PR. Then click **Review and add UI regression coverage** and review the prefilled
prompt before sending.

After production changes, recreate the complete topology so every application, sidecar, and
dependency uses a coherent build:

```bash
cd src
docker compose down
docker compose up -d --build
docker compose ps
curl --fail http://127.0.0.1:8901/health/ready
cd ..
```

## Demo 3: make the behavior durable

The **UI Test Engineer** derives a focused C# Playwright regression from the Bug's reproduction
evidence and acceptance criteria. Do not prescribe its concrete products, quantities, action
sequence, assertions, or Page Object implementation in this runbook. The generated coverage
should prove the user-visible correction, protect relevant neighboring cart state, and verify the
resulting totals.

Human review checkpoint:

- Test intent is readable without selectors.
- Selectors and waits remain in the relevant Page Object.
- The journey and assertions are traceable to the Bug rather than a prewritten test recipe.
- State-changing actions wait for their observable postconditions without assuming that a new DOM
  element must appear.
- The test uses no fixed delay and no direct `IPage` access.
- The focused test passes against the rebuilt stack.
- The agent reports the exact command and result.

Run the generated cart regression visibly for the audience. The zero-test guard prevents a
renamed or missing test from producing a false-green result:

```bash
HEADED=1 dotnet test \
  --project src/systemtests/FastFood.Ui.System.Tests/FastFood.Ui.System.Tests.csproj \
  --configuration Release --no-restore --no-ansi --zero-tests-policy strict \
  --filter-method "*Cart*"
```

Click **Review and hand off for local change review**.

## Demo 4: peer review

The **Local Change Reviewer** compares the entire working tree with the merge base of
`demo-coworkers`, including committed, staged, unstaged, and untracked files. It must not edit
anything and returns the enterprise report with findings, acceptance-criteria traceability,
verification, residual risks, and verdict.

If the first pass returns `changes required`, click **Address findings (changes required only)**.
After the correction, use **Add or verify UI regression coverage** only when user-visible behavior,
selectors, waits, or acceptance criteria changed; otherwise use **Re-review addressed findings**
directly. Existing adequate UI coverage should be verified without unnecessary edits.

The second reviewer pass is the final automated pass: `ready for PR` and
`ready with residual risk` exit the loop. Remaining findings produce `human decision required`;
do not start a third correction cycle during the demo.

If time remains, push and open an Azure Repos PR without merging it:

```bash
git push -u origin HEAD

az repos pr create \
  --organization https://dev.azure.com/4tecture-demo \
  --project k8sDemo \
  --repository FastFood \
  --source-branch "$(git branch --show-current)" \
  --target-branch demo-coworkers \
  --title "Fix repeated product quantities in shopping cart" \
  --work-items WORK_ITEM_ID \
  --open
```

In the PR, manually request the enabled GitHub Copilot Code Review. The target branch already
contains the repository and scoped review instructions. Do not complete the PR during the talk.

Finally, open `.github/agents/delivery-orchestrator.agent.md` and explain that it can delegate
the same four roles autonomously; keep the reviewed handoff version as the live workflow.

## Rehearsal and recovery

Any externally created rehearsal artifact must be prefixed `[REHEARSAL]` and closed afterward.
Do rehearsals on a disposable `rehearsal/coworkers-*` branch, never on `demo-coworkers`.

Safe recovery when an agent changes something unexpectedly:

```bash
git status --short --branch
git diff
git stash push --include-untracked --message "copilot-demo-recovery"
git switch demo-coworkers
```

The stash is recoverable with `git stash list` and `git stash show --patch`. Avoid hard resets
or deleting branches on stage.

If browser state becomes confusing, start a fresh Copilot agent session and a fresh POS order.
If the application becomes unhealthy, preserve logs first:

```bash
cd src
docker compose ps
docker compose logs --tail=200 orderservice orderserviceactors
docker compose down
docker compose up -d --build
docker compose ps
curl --fail http://127.0.0.1:8901/health/ready
```

If an MCP write fails, keep the generated report in the chat, show the evidence, and continue
with the existing rehearsal work item. Never paste a token or secret into chat.
