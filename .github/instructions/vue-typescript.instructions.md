---
applyTo: "src/services/frontend*/**/*.{vue,ts,js}"
---

# Vue and TypeScript conventions

- Follow existing Vue 3 Composition API, Pinia, Vite, and TypeScript patterns.
- Preserve accessible names, keyboard behavior, and responsive layouts.
- Prefer stable `data-testid` and descriptive `data-*` attributes for automation.
- Never use translated display text as the only automation selector when a stable ID exists.
- Keep business behavior in the existing store/service layer rather than duplicating it in views.
- Avoid production UI changes for a test unless a stable selector or observable state is missing.
