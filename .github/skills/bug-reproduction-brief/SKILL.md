---
name: bug-reproduction-brief
description: Reproduce a reported FastFood defect in the running local application, capture evidence, distinguish observations from hypotheses, and produce a professional reproduction brief without modifying source code. Use before creating a bug or attempting a repair.
---

# Bug Reproduction Brief

Create evidence that another engineer can independently replay. Stop before repair.

Adapted for FastFood from GitHub's
[awesome-copilot bug-reproduction-brief skill](https://github.com/github/awesome-copilot/blob/main/skills/bug-reproduction-brief/SKILL.md),
retrieved 2026-08-24.

## Preconditions

1. Run `git status --short --branch` and retain the output.
2. Check `curl --fail http://127.0.0.1:8901/health/ready` and the POS URL.
3. If required, start the documented full stack. Do not rebuild unless it is unavailable.
4. Create `output/playwright/` for local evidence; it is intentionally ignored by Git.

## Reproduction protocol

1. Restate the report as one observable expected/actual claim.
2. Define the shortest customer journey that can prove or disprove the claim.
3. Start with a new order/cart and record the exact input values.
4. Exercise the journey using VS Code built-in browser tools. Read the page after each
   state-changing action instead of relying on timing.
5. Capture a PNG showing the actual result. Use focused `runPlaywrightCode` only when a
   file-backed screenshot is needed, and save it below `output/playwright/`.
6. Reset to a new order/cart and repeat the same journey once more.
7. Record both outcomes separately. A single transient occurrence is inconclusive.

## Diagnosis boundary

After the two reproductions, source inspection may identify candidate components or code
paths. Label each statement as `Observation`, `Hypothesis`, or `Unknown`. Do not modify
files, run formatters, generate code, or describe a hypothesis as confirmed root cause.

If the report cannot be reproduced, stop with the evidence gathered and the next diagnostic
step. Do not create a bug solely from an assumption.

## Required output

```markdown
## Reproduction verdict
Verified | Not reproduced | Inconclusive

## Environment
- Branch and commit:
- Stack health:
- URL and timestamp/time zone:

## Steps
1. ...

## Expected
...

## Actual
...

## Evidence
- Run 1:
- Run 2:
- Screenshot:

## Impact
...

## Analysis
- Observation:
- Hypothesis:
- Unknown:

## Acceptance criteria
- [ ] ...
```

Finish by running `git status --short` and proving the working tree is unchanged.
