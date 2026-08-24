---
name: fastfood-bugfix
description: Implement a verified FastFood defect from an Azure DevOps Bug or GitHub issue using a local bugfix branch, a failing regression test, an architecture-complete minimal change, and evidence-based verification. Use only after a defect has been reproduced.
---

# FastFood Bugfix

Move a verified defect from work item to a locally reviewed implementation. Do not push,
create a PR, merge, or change work-item state.

The specialist/minimal-diff pattern is adapted for FastFood from GitHub's
[awesome-copilot SWE subagent](https://github.com/github/awesome-copilot/blob/main/agents/swe-subagent.agent.md),
retrieved 2026-08-24.

## Workflow

1. Read the complete work item, evidence, and acceptance criteria.
2. Confirm `demo-coworkers` is clean and current. Create:
   - Azure DevOps: `bugfix/{work-item-id}-cart-quantity`
   - GitHub: `bugfix/gh-{issue-number}-cart-quantity`
3. Trace the request from controller/DTO through the selected processing service, storage,
   emitted events, and consumers. Load [the order processing map](references/order-processing-map.md)
   when shared order behavior is involved.
4. Add the smallest unit regression that proves the incorrect behavior. Run it before editing
   production code and retain the failing command/output.
5. Implement the smallest change that satisfies the acceptance criteria across every applicable
   processing implementation. Preserve routes, DTOs, event contracts, and serialized state shapes.
6. Run the focused test again, then the affected project tests and solution build.
7. Rebuild affected Compose services and wait for healthy status. Do not tear down healthy
   infrastructure unnecessarily.
8. Repeat the original browser journey and compare it with the investigator's evidence.
9. Review `git diff --check` and `git diff demo-coworkers...HEAD` for accidental scope.

Never copy a solution from another branch. Repository history may be inspected for context only
when the user explicitly asks; the live exercise is meant to derive the fix from evidence and code.

## Completion dossier

- Work item and acceptance criteria addressed.
- Local branch and merge base.
- Failing regression command/result before the fix.
- Passing targeted tests and build after the fix.
- Applicable state/actor/workflow paths inspected and changed or justified.
- Browser verification and screenshot path.
- Files changed and residual risks.
