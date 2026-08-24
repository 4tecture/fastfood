---
name: azure-devops-bug-report
description: Create a professional Azure DevOps Bug for a verified FastFood defect in the 4tecture-demo k8sDemo project, including reproducible evidence and a PNG attachment. Supports deterministic repeat presentations with demo-run=true. Use after bug reproduction when tracker=azure-devops.
---

# Azure DevOps Bug Report

Defaults:

- Organization: `https://dev.azure.com/4tecture-demo`
- Project: `k8sDemo`
- Work-item type: `Bug`
- `demo-run`: `false` unless explicitly set to `true`

## Procedure

1. Require a verified reproduction brief with two runs and a PNG under `output/playwright/`.
2. Apply exactly one duplicate policy:
   - With `demo-run=true`, do not search for duplicates. Create a new Bug and add the
     `copilot-demo` tag.
   - Otherwise, run one bounded duplicate search. Search only Bugs in `New`, `Approved`, or
     `Committed`; exclude items tagged `copilot-demo` and titles beginning `[REHEARSAL]`;
     inspect no more than five candidates. Treat only the same product area, user action, and
     observed behavior as a likely duplicate. If one exists, report it and stop unless the user
     explicitly asks to create another.
3. Inspect the Bug work-item type when necessary so only supported fields are written.
4. Create the Bug with Azure DevOps MCP when its write tool is available. Otherwise use
   `az boards work-item create` with the explicit organization and project.
5. Use a concise customer-visible title without an implementation guess.
6. Populate supported fields with: description/impact, environment, numbered reproduction steps,
   expected behavior, actual behavior, evidence from both runs, labeled hypotheses, and testable
   acceptance criteria.
7. Attach the PNG after the Bug exists:

```bash
.github/skills/azure-devops-bug-report/scripts/attach-work-item-screenshot.sh \
  WORK_ITEM_ID output/playwright/SCREENSHOT.png
```

8. Read the created Bug back and verify its type, title, content, attachment relation, ID, and URL.

Do not expose authentication tokens, include secrets in evidence, assign an engineer, change
state, or create a PR. Return the Bug ID and browser URL.
