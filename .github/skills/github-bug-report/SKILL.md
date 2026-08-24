---
name: github-bug-report
description: Create a professional GitHub issue for a verified FastFood defect, with duplicate detection, structured evidence, and a private-repository-safe screenshot reference. Use after bug reproduction when tracker=github.
---

# GitHub Bug Report

Default to the repository resolved from the Git remote named `github`
(`marc-mueller/dapr-fastfood`). Honor an explicit owner/repository or remote override.

Adapted from GitHub's current
[awesome-copilot GitHub Issues skill](https://github.com/github/awesome-copilot/blob/main/skills/github-issues/SKILL.md),
retrieved 2026-08-24.

## Procedure

1. Require a verified reproduction brief with two runs and a PNG under `output/playwright/`.
2. Resolve and confirm the target owner/repository before any external write.
3. Use GitHub MCP to search open issues for likely duplicates and inspect issue types/labels.
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
