# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Vue 3.5 + Vite (three frontend SPAs) · .NET 10 backend microservices · Dapr 1.18 (pub/sub, state, actors, workflows) · Tailwind CSS 4.1 · Docker Compose / Kubernetes (AKS)

## Users

**Kiosk customer** — a fast-food restaurant guest standing at an unattended self-service terminal, placing an order and paying without staff assistance. Sessions are stateless per visit (fresh targeting per customer).

**Kitchen staff** — food-preparation workers monitoring a shared kitchen display, marking individual order items as finished as they complete them.

**Waiting customer** — a guest who has already ordered, watching a public display board to see when their order moves from "in preparation" to "ready".

**Developer / architect learner** — an engineer studying Dapr patterns (actors, state, workflows), feature flag–driven A/B testing, observability with OpenTelemetry, and CI/CD pipelines using this repo as a reference or workshop vehicle.

## Product Purpose

FastFood is a fully working fast-food order and fulfillment system — real end-to-end flows from kiosk ordering through kitchen processing to payment — built simultaneously as a production-grade microservices reference app and a teaching vehicle. It demonstrates three parallel implementation patterns for the same domain (actor-based, state-based, workflow-based), runtime-switchable feature flags, surge pricing, loyalty discounts, and full observability. Success means the system works correctly as a restaurant app and is easy to reason about as a learning artifact.

## Positioning

The product's meaningful difference is that it ships the same business domain in three competing Dapr implementation strategies side-by-side, routing live traffic between them — something a neighboring demo or production app cannot truthfully replicate.

## Operating Context

- **POS surface:** unattended kiosk, touch-first, single-session flows (browse → cart → confirm → pay → reset). Each "Start Ordering" generates a fresh user ID for feature-flag targeting.
- **Kitchen Monitor:** wall-mounted or tabletop display in a kitchen; glance-and-tap interaction; real-time updates via SignalR.
- **Customer Order Status:** large public display board; no interaction required; auto-updating two-column view (in preparation / ready).
- **Developer context:** local Docker Compose stack with Dapr sidecar, RabbitMQ, Redis, Grafana, Loki, Prometheus, Traefik reverse proxy, and Azure App Configuration for dynamic feature flags.

## Capabilities and Constraints

- Three order-processing implementations (actor, state, workflow) coexist; `OrderEventRouter` routes each order to its target, stored in Redis.
- Feature flags (Azure App Configuration): `LoyaltyProgram`, `NewCheckoutExperience`, `DarkMode`, `UseWorkflowImplementation`, `DynamicPricing`, `AutoPrioritization` — all runtime-switchable.
- Currency: USD, formatted as `$0.00`.
- Order types: `Inhouse` (shown on customer status board) and others (filtered out).
- Finished orders on the status board are capped at 10 entries (FIFO eviction).
- No authentication on any frontend surface (kiosk and display board are public by design).

## Brand Commitments

Name: **FastFood**. No logo, color palette, typeface, or visual identity has been established. All three frontends use Tailwind's default system-font stack and a neutral gray-and-blue palette. These are open decisions — not constraints.

## Evidence on Hand

- Full working source code for all three frontend SPAs and all backend microservices.
- No marketing copy, testimonials, product screenshots, or brand assets exist yet.
- Demo scripts and observability queries in `demos/` and `docs/`.

## Product Principles

1. **Working system first.** Every pattern and flag must be demonstrable on a real, running order flow — no mocked-out shortcuts.
2. **Transparent trade-offs.** The three implementation strategies are side-by-side so learners can compare real complexity, not abstractions.
3. **Runtime changeability.** Feature flags, implementation routing, and pricing rules must change without a deploy — that is the point.
4. **Operate over impress.** Kitchen and status surfaces optimise for glanceability and accuracy; the kiosk optimises for speed of completion.
5. **Evidence-grounded demos.** Observability, telemetry, and CI/CD pipelines are first-class — the product teaches by being fully instrumented.

## Accessibility & Inclusion

WCAG 2.1 AA is the confirmed minimum standard across all three frontend surfaces.
