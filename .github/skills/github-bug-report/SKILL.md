---
name: github-bug-report
description: Create a professional GitHub issue for a verified FastFood defect, with bounded duplicate detection, structured evidence, and a private-repository-safe screenshot reference. Supports deterministic repeat presentations with demo-run=true. Use after bug reproduction when tracker=github.
---

# GitHub Bug Report

Default to the repository resolved from the Git remote named `github`
(`marc-mueller/dapr-fastfood`). Honor an explicit owner/repository or remote override.
Treat `demo-run` as `false` unless explicitly set to `true`.

Adapted from GitHub's current
[awesome-copilot GitHub Issues skill](https://github.com/github/awesome-copilot/blob/main/skills/github-issues/SKILL.md),
retrieved 2026-08-24.

## Procedure

1. Require a verified reproduction brief with two runs and a PNG under `output/playwright/`.
2. Resolve and confirm the target owner/repository before any external write.
3. Apply exactly one duplicate policy:
   - With `demo-run=true`, do not search for duplicates. Mark the new issue with an existing
     `copilot-demo` label, or add `<!-- copilot-demo -->` to the body when that label is absent.
   - Otherwise, run one bounded search of open issues. Exclude issues labeled `copilot-demo`,
     issues containing the `<!-- copilot-demo -->` marker, and titles beginning `[REHEARSAL]`;
     inspect no more than five candidates. Treat only the same product area, user action, and
     observed behavior as a likely duplicate. If one exists, report it and stop unless the user
     explicitly asks to create another.
4. Publish the screenshot using [the evidence-image workflow](references/evidence-images.md).
5. Create the issue with an available GitHub MCP write tool. If the connected server exposes
   read operations only, use `gh api repos/{owner}/{repo}/issues`.
6. Prefer organization issue type `Bug`; fall back to an existing `bug` label when issue types
   are unavailable. Do not create taxonomy solely for this demo.
7. Include: impact, environment, numbered steps, expected/actual behavior, evidence for both
   runs, the screenshot, labeled hypotheses, and testable acceptance criteria.
8. Read the issue back and return its number and URL.

Do not publish private evidence in a public gist, expose credentials, assign an engineer,
close issues, push a source branch, or create a PR.
