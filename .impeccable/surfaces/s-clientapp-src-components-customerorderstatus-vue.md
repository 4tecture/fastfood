---
version: 1
slug: "s-clientapp-src-components-customerorderstatus-vue"
primary_target: "src/services/frontendcustomerorderstatus/FrontendCustomerOrderStatus/clientapp/src/components/CustomerOrderStatus.vue"
related_targets: ["src/services/frontendcustomerorderstatus/FrontendCustomerOrderStatus/clientapp/src/App.vue","src/services/frontendcustomerorderstatus/FrontendCustomerOrderStatus/clientapp/src/assets/tailwind.css","src/services/frontendcustomerorderstatus/FrontendCustomerOrderStatus/clientapp/index.html"]
---

# Customer order status

## Purpose

A large, glanceable pickup scoreboard for customers waiting in the restaurant. It should feel like the public-facing sibling of the self-service POS: energetic, direct, warm, and unmistakably fast-food.

## Audience and mode

- Audience: customers standing several metres from a shared display.
- Mode: Read.
- Primary task: find an order reference and understand whether it is being made or ready.

## Design contract

- Thesis: a fast-food pickup scoreboard, not a dashboard.
- Own-world: cream, tomato red, mustard yellow, and near-black; chunky display type and the shared FastFood wordmark.
- Story: scan from the quieter Being made field to the louder Ready for pickup field.
- First viewport: compact dark identity bar above a 42/58 split status board.
- Form: stadium pickup scoreboard; grounded structure position 3, seed d76d2c20.

## Interaction and accessibility

- Order references must remain readable at distance and use live regions for status changes.
- Readiness is communicated by wording, scale, field color, and token color—not color alone.
- The realtime indicator must distinguish connecting, live, and offline states truthfully.
- At narrower widths, stack the two status fields without losing their relative visual priority.
