---
name: local-change-review
description: Review a local FastFood change set against demo-coworkers without editing files. Use after implementation and regression coverage to find actionable correctness, architecture, compatibility, security, or test defects before a PR.
---

# Local Change Review

Review only. Do not edit, stage, commit, switch branches, push, create a PR, or update a work item.

## Procedure

1. Read the work item, evidence, and acceptance criteria.
2. Establish the comparison safely:

```bash
git status --short --branch
git merge-base demo-coworkers HEAD
git diff --stat demo-coworkers...HEAD
git diff --check demo-coworkers...HEAD
git diff demo-coworkers...HEAD
```

3. Inspect complete files around changed hunks and the tests that cover them.
4. Trace shared order behavior through state, actor, and workflow implementations.
5. Check in priority order:
   - incorrect or incomplete behavior and edge cases;
   - inconsistent implementations, event/state compatibility, concurrency, and idempotency;
   - missing or false-positive regression coverage and flaky waits;
   - security, secrets, unsafe logging, and destructive behavior;
   - public contract changes and unrelated scope.
6. Run relevant builds/tests only when they do not mutate tracked files. State what was not run.

Do not report personal style preferences or speculative concerns without a concrete failure mode.

## Finding format

```markdown
### [P1|P2|P3] Short actionable title
- Location: `path:line`
- Failure mode: what breaks and under which conditions
- Evidence: code path, test result, or acceptance criterion
- Required correction: the behavior that must change
```

Finish with a verdict: `ready for PR`, `ready with residual risk`, or `changes required`.
