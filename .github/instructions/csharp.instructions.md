---
applyTo: "**/*.cs"
---

# C# and Dapr conventions

- Keep nullable reference types correct and preserve the existing async APIs.
- Pass cancellation tokens through when the surrounding contract supports them.
- Use structured logging and existing source-generated logging patterns; never log secrets.
- Reuse constants for Dapr app IDs, components, pub/sub topics, and state keys.
- Preserve optimistic concurrency, state-store metadata, event ordering, and idempotency
  behavior unless the task explicitly changes that contract.
- Keep controller actions thin and place domain behavior in the existing service, actor,
  or workflow layer.
- For shared order behavior, inspect the state, actor, and workflow implementations before
  deciding the change is complete.
- Follow the surrounding file's formatting and naming conventions; avoid unrelated cleanup.
