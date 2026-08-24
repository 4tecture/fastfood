---
applyTo: "**/*Tests.cs"
---

# xUnit test conventions

- Use xUnit v3 and the repository's existing fixture, mock, and assertion patterns.
- Name tests as observable behavior, with Arrange, Act, and Assert kept easy to scan.
- Add a regression test that fails for the reported behavior before changing production code.
- Assert externally meaningful state and interactions, not implementation trivia.
- Cover affected order-processing variants when their behavior is contractually equivalent.
- Keep tests deterministic; do not use wall-clock sleeps or depend on execution order.
