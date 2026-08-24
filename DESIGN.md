---
name: FastFood
description: A high-energy, highly legible fast-food interface system built for quick decisions and confident completion.
colors:
  cream-ground: "#fff8e9"
  cream-layer: "#ffedc2"
  near-black-ink: "#201b18"
  muted-warm-ink: "#65584f"
  tomato-red: "#d93622"
  tomato-red-hover: "#b72517"
  mustard-yellow: "#ffd43b"
  warm-rule: "#dbcdb6"
  pure-white: "#ffffff"
  focus-blue: "#1769e0"
  graphite-ground: "#171411"
  graphite-panel: "#221e1a"
  graphite-panel-raised: "#2b2520"
  graphite-rule: "#4c4038"
  kitchen-tomato: "#ff5a3d"
  kitchen-tomato-hover: "#ff765f"
  completion-green: "#9fcd85"
  error-coral: "#ff8b78"
  kitchen-focus-blue: "#7db5ff"
  kitchen-action-ink: "#20120e"
typography:
  wordmark:
    fontFamily: "Paytone One, Bricolage Grotesque, sans-serif"
    fontSize: "clamp(1.25rem, 2vw, 1.75rem)"
    fontWeight: 400
    lineHeight: 1
    letterSpacing: "-0.035em"
  display:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2.25rem, 5vw, 5.5rem)"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "-0.04em"
  headline:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2rem, 4vw, 4rem)"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.04em"
  title:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "2rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "-0.035em"
  body:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 650
    lineHeight: 1.45
    letterSpacing: "normal"
  label:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "0.09em"
  numeric:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.375rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "normal"
    fontFeature: "tnum"
  action:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "normal"
rounded:
  brand: "4px"
  compact: "10px"
  control: "12px"
  tactile: "14px"
  panel: "16px"
  pill: "999px"
spacing:
  xs: "0.5rem"
  sm: "0.75rem"
  md: "1rem"
  lg: "1.5rem"
  xl: "2rem"
  "2xl": "3rem"
components:
  wordmark:
    backgroundColor: "{colors.near-black-ink}"
    textColor: "{colors.pure-white}"
    typography: "{typography.wordmark}"
    rounded: "{rounded.brand}"
    padding: "0.18rem 0.35rem 0.25rem 0.08rem"
  button-primary:
    backgroundColor: "{colors.tomato-red}"
    textColor: "{colors.pure-white}"
    typography: "{typography.action}"
    rounded: "{rounded.tactile}"
    padding: "1rem 1.5rem"
    height: "58px"
  button-primary-hover:
    backgroundColor: "{colors.tomato-red-hover}"
    textColor: "{colors.pure-white}"
    typography: "{typography.action}"
    rounded: "{rounded.tactile}"
    padding: "1rem 1.5rem"
    height: "58px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.near-black-ink}"
    typography: "{typography.action}"
    rounded: "{rounded.tactile}"
    padding: "0.875rem 1.5rem"
    height: "54px"
  quantity-button:
    backgroundColor: "{colors.cream-layer}"
    textColor: "{colors.near-black-ink}"
    typography: "{typography.action}"
    rounded: "{rounded.control}"
    size: "46px"
  ready-token:
    backgroundColor: "{colors.tomato-red}"
    textColor: "{colors.pure-white}"
    typography: "{typography.display}"
    rounded: "{rounded.tactile}"
    padding: "1rem"
    height: "clamp(6.5rem, 15vh, 10rem)"
  workload-counter:
    backgroundColor: "{colors.mustard-yellow}"
    textColor: "{colors.near-black-ink}"
    typography: "{typography.numeric}"
    rounded: "{rounded.control}"
    padding: "0.65rem 0.8rem"
  kitchen-ticket:
    backgroundColor: "{colors.graphite-panel}"
    textColor: "{colors.cream-ground}"
    rounded: "{rounded.tactile}"
  kitchen-finish-action:
    backgroundColor: "{colors.kitchen-tomato}"
    textColor: "{colors.kitchen-action-ink}"
    typography: "{typography.action}"
    rounded: "{rounded.control}"
    padding: "0.7rem 1rem"
    height: "48px"
---

# Design System: FastFood

## Overview

**Creative North Star: "The Fast Counter"**

FastFood should feel like the instant recognition and decisive rhythm of a great fast-food counter: energetic, direct, warm, chunky, and useful. Public and customer-facing surfaces use broad cream fields, tomato actions, mustard highlights, near-black ink, and oversized information so a person can decide at a glance or from several metres away.

The kitchen translates the same identity into an internal flight deck. Warm graphite replaces cream as the ground; cream type, tomato actions, mustard workload counts, and green completion preserve the family resemblance while reducing visual noise under pressure. The system is emphatically not classy, upscale, corporate-dashboard-like, or overly decorative.

Motion is brief and purposeful: clipped arrival for newly important information and a concise reveal for completion. Every animation must collapse to effectively instantaneous behavior when reduced motion is requested.

**Key Characteristics:**

- Warm high-contrast fields rather than cool neutral application chrome.
- Chunky, compact typography with unmistakable numeric priority.
- Tomato for action and readiness; mustard for attention and workload.
- Flat tonal layering, visible rules, and only one exceptional shadow role.
- Moderate tactile corners, with pills reserved for compact counters and status.

## Colors

The public palette behaves like a fast-food counter under warm light; the kitchen palette is its calmer graphite translation, not a separate brand.

### Primary

- **Tomato Red:** The public action and readiness color. Use it for primary calls to action, the emphasized half of the wordmark, and the highest-priority customer state.
- **Tomato Red Hover:** The darker interaction response for public primary actions.
- **Kitchen Tomato:** A brighter tomato calibrated for dark graphite surfaces and deliberate finish actions.
- **Kitchen Tomato Hover:** The corresponding high-contrast hover response in the kitchen.
- **Focus Blue / Kitchen Focus Blue:** Accessibility-only focus colors selected for their respective light and dark grounds; they are not brand accents.

### Secondary

- **Mustard Yellow:** The warm attention field for the persistent order rail, ready-zone ground, workload counts, and compact high-value badges.

### Tertiary

- **Completion Green:** A semantic confirmation color reserved for completed kitchen work and live operational state.
- **Error Coral:** The dark-surface semantic color for offline or failed kitchen states.

### Neutral

- **Cream Ground:** The default public canvas and light text color on dark identity surfaces.
- **Cream Layer:** The secondary public layer for controls, preparing tokens, and receipt-like groupings.
- **Near-Black Ink:** The main public text, dark identity field, and strongest structural rule.
- **Muted Warm Ink:** Supporting copy that must recede without becoming gray or cold.
- **Warm Rule:** Separates rows and sections without introducing shadow.
- **Graphite Ground:** The kitchen canvas.
- **Graphite Panel / Graphite Panel Raised:** Tonal layers for kitchen tickets and their headers.
- **Graphite Rule:** The kitchen divider and ticket outline.
- **Pure White / Kitchen Action Ink:** Narrow utility roles for maximum contrast on tomato fields.

**The Warm Signal Rule.** Tomato means action or readiness; mustard means attention or workload. Do not interchange them casually.

**The Two Worlds, One Counter Rule.** Customer surfaces stay cream-led and expressive; the kitchen stays graphite-led and restrained while keeping the same signal colors and wordmark.

## Typography

**Display Font:** Bricolage Grotesque (with `ui-sans-serif`, `system-ui`, and `sans-serif` fallbacks)  
**Body Font:** Bricolage Grotesque (with `ui-sans-serif`, `system-ui`, and `sans-serif` fallbacks)  
**Signature Font:** Paytone One (with Bricolage Grotesque and `sans-serif` fallbacks)

**Character:** Bricolage Grotesque supplies dense, friendly utility from small labels to oversized order references. Paytone One appears only where the FastFood signature needs a memorable, hand-painted counter-sign character.

### Hierarchy

- **Wordmark:** Regular-weight Paytone One with tight tracking; keep it compact and let the tomato-backed “Food” block carry recognition.
- **Display:** Extra-bold, tightly tracked, tabular where numeric; use for order references and other glance-distance information.
- **Headline:** Extra-bold with a compressed line height; use for field headings and major customer decisions.
- **Title:** Extra-bold and compact; use for ticket references, order-rail headings, and focused page titles.
- **Body:** Medium-to-bold Bricolage, generally kept to roughly 65 characters per line when descriptive copy appears.
- **Label:** Extra-bold, short, and optionally uppercase; reserve the widest tracking for truly compact labels.
- **Numeric:** Extra-bold with tabular figures for counts, prices, progress, and order references.

**The Fast Read Rule.** Weight, scale, and tabular figures do the work; do not add ornamental type treatments to operational information.

**The Signature Is Scarce Rule.** Paytone One belongs to the FastFood wordmark and rare display accents, never paragraphs, controls, or dense kitchen data.

## Layout

The system uses strong field boundaries rather than floating card stacks. Public flows are generous and directional, with large padding and one dominant next action. Operational layouts compress the same rhythm into sticky summaries, dense grids, and rows that keep unfinished work and its action in the same scan line.

Spacing follows the extracted half-rem rhythm, from compact 0.5rem gaps through 3rem page insets. Public surfaces commonly expand padding with `clamp()`; dense kitchen grids reduce to 1rem gutters on narrow screens. Implemented responsive transitions range from 36rem to 64rem and preserve action reachability and key counts before decorative or descriptive content.

Touch targets are never smaller than the extracted 44–48px compact controls; primary actions run 54–64px tall. Text measures stay bounded, while order references, totals, and workload counts are allowed to dominate.

**The Field Before Card Rule.** Establish hierarchy with background fields, rules, and scale before introducing another container.

**The Action Stays Attached Rule.** On every breakpoint, the control remains visually and structurally attached to the item or decision it changes.

## Elevation & Depth

FastFood is flat and tonal by default. Cream-on-cream or graphite-on-graphite layers, explicit 1–3px rules, and high-contrast field color establish depth. The single canonical shadow is the restrained ready-pickup token shadow (`0 10px 24px rgba(111, 39, 15, 0.2)`), used because readiness must lift above the public board at a glance.

### Shadow Vocabulary

- **Ready Pickup Lift** (`0 10px 24px rgba(111, 39, 15, 0.2)`): Only for high-priority ready pickup tokens.

**The Flat-by-Default Rule.** If color, a rule, or spacing can establish the layer, do not add a shadow.

**The Ready Lift Rule.** Shadow is a semantic privilege of ready pickup, not generic polish for cards or controls.

## Shapes

Controls and tickets use moderate 12–14px corners so they feel tactile without becoming soft or toy-like. Larger focused containers may use 16px; compact dismiss controls use 10px. The wordmark’s tomato block stays tighter at 4px. Full pills are reserved for small numeric or live-status counters, never for broad actions, panels, or every label.

Borders are functional: 1px graphite rules separate dense kitchen work, while public dividers and important totals use 2–3px warm or near-black rules. Image and token clipping follows the same moderate corner language.

**The Pill Ration Rule.** Use 999px only when the object is intrinsically compact—a count, dot, or short status—not as a default component silhouette.

## Components

### Shared Wordmark

- **Character:** Compact and immediate, with Paytone One and tightly joined “Fast” and “Food.”
- **Construction:** “Fast” sits directly on the surface; “Food” uses a near-black or tomato block with white type and a tight 4px corner.
- **Use:** Keep one lockup per primary identity region; do not turn it into a large decorative pattern.

### Buttons

- **Shape:** Tactile 12–14px corners with an explicit 2px border and bold Bricolage label.
- **Primary:** Tomato on public surfaces; brighter kitchen tomato on graphite. Full-width decision buttons are 58px tall, while the compact kitchen finish action is at least 48px.
- **Hover / Active:** Shift to the extracted hover tomato and use no more than a 1–2px translation; active states return toward the surface.
- **Focus:** Use a 3px blue outline with 3–4px offset so focus never depends on the tomato color change.
- **Secondary:** Transparent with a 2px near-black border on cream; invert to near-black on hover.

### Quantity Controls

- **Style:** Square 46px cream-layer controls with 12px corners, a centered bold symbol, and a fixed-width numeric count.
- **State:** Tomato border on hover, blue focus outline, and a brief 0.96 active scale.

### Order Rails and Summaries

- **Style:** Mustard is a persistent, high-attention field for the customer’s current order or an operational count—not a decorative sidebar color.
- **Structure:** Use strong horizontal rules, tabular prices/counts, and a dark or tomato final action. Summary content remains scannable when the rail docks to a screen edge.

### Ready Tokens and Workload Counters

- **Ready Token:** Large tomato field, white tabular reference, 14px corners, and the single Ready Pickup Lift shadow.
- **Workload Counter:** Compact mustard field, near-black tabular count, 12px corners, and no shadow.
- **Arrival:** New ready tokens use a 420ms clipped reveal with `cubic-bezier(0.16, 1, 0.3, 1)`; reduced motion removes the reveal.

### Kitchen Tickets and Finish Actions

- **Ticket:** Graphite panel with a 1px graphite rule and 14px corners; a slightly lighter graphite header carries the order reference and progress.
- **Rows:** Minimum 72px row height, unfinished work first, mustard quantity, cream item text, and one attached finish action.
- **Finish / Done:** The 48px tomato Finish action becomes a green textual Done state. Completion reveals in 360ms with the same purposeful easing; reduced motion removes the reveal.
- **Error / Disabled:** Busy actions expose disabled and busy states; error coral and explicit wording carry failure.

**The One Deliberate Action Rule.** Every operational row exposes one obvious, reachable action and an equally explicit completed state.

## Do's and Don'ts

### Do:

- **Do** use cream, tomato, mustard, and near-black as the public identity, then translate them to graphite, cream, tomato, mustard, and green for the kitchen.
- **Do** make hierarchy visible through field color, type scale, strong rules, and whitespace.
- **Do** keep numeric information tabular, extra-bold, and readable at the surface’s actual viewing distance.
- **Do** preserve at least 44–48px touch targets and visible 3px focus outlines.
- **Do** limit motion to brief arrival and completion feedback and honor `prefers-reduced-motion` everywhere.

### Don't:

- **Don't** make FastFood feel classy, upscale, corporate-dashboard-like, cool-neutral, or overly decorative.
- **Don't** use generic card grids when one strong field or rule can communicate the same structure.
- **Don't** add shadows to routine controls, counters, or kitchen tickets; reserve the canonical lift for ready pickup.
- **Don't** use excessive pills, ornamental gradients, glass effects, or soft ambient decoration.
- **Don't** use Paytone One for body copy, dense operational data, or control labels.
