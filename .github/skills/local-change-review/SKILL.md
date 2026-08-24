---
name: local-change-review
description: Perform an enterprise-grade, read-only review of a FastFood change set against a target branch, including committed, staged, unstaged, and untracked changes. Use after implementation or regression coverage to assess acceptance-criteria traceability, correctness, architecture, compatibility, security, tests, and delivery readiness before a PR.
---

# Enterprise Local Change Review

Review only. Do not edit, stage, commit, switch branches, push, create a PR, or update a work item.

## Required workflow

1. Read the work item, evidence, and acceptance criteria.
2. Resolve the target branch from the request, defaulting to `demo-coworkers`. Establish one
   merge base and review the entire working tree relative to it:

```bash
git status --short --branch
review_target="demo-coworkers" # Replace when the request names another target.
git rev-parse --verify "$review_target"
git log --oneline "$review_target"..HEAD
review_merge_base="$(git merge-base "$review_target" HEAD)"
git diff --name-status "$review_merge_base"
git diff --stat "$review_merge_base"
git diff --check "$review_merge_base"
git diff "$review_merge_base"
git ls-files --others --exclude-standard
```

   `git diff "$review_merge_base"` includes committed, staged, and unstaged tracked changes.
   Read every untracked file reported by `git ls-files`; do not omit it because Git has no diff
   entry yet. Do not require the implementation to be committed.
3. Inspect complete files around changed hunks, callers, consumers, and the tests that cover them.
4. Trace each acceptance criterion to implementation and executable evidence.
5. Review through these lenses, in order:
   - behavior, edge cases, error paths, concurrency, and idempotency;
   - consistency across state, actor, and workflow implementations when shared order behavior
     changes;
   - Dapr state/event compatibility and public API/DTO/route stability;
   - regression quality, false positives, stable selectors, observable waits, and flakiness;
   - security, secrets, unsafe logging, validation, and destructive behavior;
   - performance regressions, dependency changes, maintainability, and unintended scope.
6. Run relevant builds/tests only when they do not mutate tracked files. Record exact commands,
   outcomes, and checks not run. Never infer a pass from source inspection.

Do not report personal style preferences or speculative concerns without a concrete failure mode.

## Severity

| Severity | Criteria |
|---|---|
| `BLOCKER` | Data loss, security breach, broken public contract, or unusable primary workflow |
| `HIGH` | Likely production defect, missing architecture path, or unreliable required regression |
| `MEDIUM` | Material edge case, compatibility risk, or incomplete acceptance-criteria coverage |
| `LOW` | Concrete maintainability or non-critical test weakness with a justified correction |

Do not emit `NIT` findings. Omit severity sections that contain no findings.

## Mandatory report

Produce one Markdown report with these sections:

### 1. Overview

- Work item and intent.
- Target branch, current branch, merge base, commits, and working-tree state.
- Files and architectural areas reviewed.

### 2. Findings

Group findings under `#### BLOCKER`, `#### HIGH`, `#### MEDIUM`, and `#### LOW`. Use this table
for every finding:

```markdown
##### Short actionable title

| Field | Content |
|---|---|
| Location | `path:line` and symbol |
| Risk / impact | What fails, under which conditions, and why the severity applies |
| Evidence | Code path, command result, or unmet acceptance criterion |
| Required correction | The behavior that must change; do not implement it |
| Verify | The command or scenario that proves the correction |
```

If there are no findings, state `No actionable findings.`

### 3. Acceptance-criteria traceability

Use a table with criterion, implementation evidence, test evidence, and status
(`satisfied`, `partial`, or `missing`).

### 4. Verification

List every command and result, followed by checks not run and the reason.

### 5. Residual risks and follow-ups

Include only concrete residual risk or intentionally deferred work. Write `None.` when empty.

### 6. Verdict

Return exactly one:

- `ready for PR`: no findings remain and required verification passed.
- `ready with residual risk`: no actionable finding remains, but a material check could not run.
- `changes required`: one or more actionable findings remain on the first review pass.
- `human decision required`: findings remain on the second review pass; stop instead of starting
  a third correction cycle.
