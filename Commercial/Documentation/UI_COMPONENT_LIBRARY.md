# UI_COMPONENT_LIBRARY.md

**Phase 8 · Sprint 4**  
**Purpose:** Reusable enterprise components for Professional shell / portal / future dashboard chrome  
**Rule:** Components display and navigate — they never execute trades

---

## 1. Buttons

| Variant | Use |
|---------|-----|
| Primary | Gold fill / dark text or gold outline on black — main CTA |
| Secondary | Elevated surface + ivory text |
| Ghost | Transparent, border optional |
| Danger | Error red — destructive confirms only |
| Icon | Square/compact for toolbars |

States: default · hover · active · disabled · loading  
Size: `sm` · `md` · `lg`  
Rule: one primary CTA per panel.

---

## 2. Cards / Panels

| Type | Use |
|------|-----|
| Panel | Structural regions (nav, trading side, footer) |
| Card / Widget | Modular status tiles in workspace |
| Section header | Title + optional actions |

Cards are for **interaction or glanceable metrics** — not decorative boxes around every sentence.

---

## 3. Tables

| Feature | Spec |
|---------|------|
| Density | Compact for positions/history |
| Header | Sticky optional; muted ivory |
| Row hover | Subtle elevated wash |
| Numeric cols | Right-align, tabular figures |
| Empty | Dedicated empty state (see §10) |

---

## 4. Charts

| Type | Typical use |
|------|-------------|
| Line | Equity / balance |
| Area | Soft under equity (low opacity) |
| Bar | Session volume / distribution |
| Sparkline | Widget-sized trend |

Charts must remain readable at widget size; no 3D effects.

---

## 5. Progress indicators

| Kind | Use |
|------|-----|
| Determinate bar | Downloads, long jobs |
| Indeterminate | Unknown duration |
| Stepper | Wizard / onboarding only |

Never fake progress for trading “AI thinking.”

---

## 6. Status badges

Pill or compact tag with icon + short label:

`Active` · `Warning` · `Error` · `Offline` · `Grace` · `Expired` · `Demo` · `Live`

---

## 7. Notifications

| Channel | Spec |
|---------|------|
| Toast | Transient, corner stack, auto-dismiss |
| Banner | Persistent until action (license grace, connection) |
| Bell tray | Notification center in top nav |

Severity maps to semantic colors. No sound by default (optional user pref).

---

## 8. Tooltips

- Delay ~400ms  
- Concise; no paragraphs  
- Keyboard accessible (focus)  
- Prefer clarifying truncated labels / icons  

---

## 9. Dialogs

| Kind | Use |
|------|-----|
| Modal | Confirm destructive / license / critical settings |
| Drawer | Secondary detail without leaving page |
| Popover | Lightweight menus |

Always: title · body · primary + cancel. Esc / focus trap required in shell UIs.

---

## 10. Loading states

- Skeleton for widget grids  
- Spinner for local actions  
- Disable double-submit on buttons  

---

## 11. Empty states

Structure: icon · one sentence · one CTA  
Examples: “No open positions” · “No invoices yet” · “Connect license to continue”

Tone: calm, premium — never blame the user.

---

## 12. Form controls

Inputs, selects, toggles, checkboxes — match radius-sm, clear focus ring, error text below field.

---

## 13. Widget contract (modular)

Every widget implements:

| Field | Meaning |
|-------|---------|
| `id` | Stable commercial id (not sprint remapped casually) |
| `title` | Customer language |
| `value` / `spark` | Primary metric |
| `status` | ok / warn / error / unknown |
| `href` | Optional deep link |
| `refresh` | Observe-only data bind |

**Stable commercial taxonomy** preferred over rotating Phase sprint labels (see prior UI reviews).

---

*End of UI_COMPONENT_LIBRARY.md*
