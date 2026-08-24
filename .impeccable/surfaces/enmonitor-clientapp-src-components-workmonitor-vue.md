---
version: 1
slug: "enmonitor-clientapp-src-components-workmonitor-vue"
primary_target: "src/services/frontendkitchenmonitor/FrontendKitchenMonitor/clientapp/src/components/WorkMonitor.vue"
related_targets: ["src/services/frontendkitchenmonitor/FrontendKitchenMonitor/clientapp/src/App.vue","src/services/frontendkitchenmonitor/FrontendKitchenMonitor/clientapp/src/assets/tailwind.css","src/services/frontendkitchenmonitor/FrontendKitchenMonitor/clientapp/index.html","src/services/frontendkitchenmonitor/FrontendKitchenMonitor/clientapp/src/stores/kitchenStore.js"]
---

# Kitchen Work Monitor

## Purpose

An internal operational workboard for cooks to see paid orders, understand remaining workload, and finish individual items with one deliberate action.

## Audience and mode

- Audience: kitchen staff working quickly in a noisy, high-attention environment.
- Mode: Operate.
- Primary task: identify unfinished items and mark each one finished.

## Design contract

- Thesis: a kitchen flight deck with fast-food energy, not a customer-facing menu.
- Own-world: warm graphite surfaces with cream text, tomato action controls, mustard workload counts, and green completion feedback.
- Story: workload summary, order ticket, unfinished items first, explicit Done state.
- First viewport: compact sticky command bar over a dense responsive workboard.
- Form: operational flight deck; grounded structure position 4, seed f6d38cec.

## Interaction and accessibility

- Finish controls are at least 48px tall, include a text label, expose busy state, and prevent duplicate actions.
- Pending items sort before completed items; completed items remain visible until the order closes.
- Loading, empty, connection, fetch-error, and action-error states are explicit.
- At narrower widths, preserve workload counts and action controls before the descriptive page title.
