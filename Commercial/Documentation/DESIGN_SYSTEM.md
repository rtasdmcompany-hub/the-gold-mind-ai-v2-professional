# DESIGN_SYSTEM.md

**Phase 8 · Sprint 4**  
**Product:** THE GOLD MIND PROFESSIONAL  
**Identity:** Premium Black · Metallic Gold · Modern Enterprise  
**Rule:** UI/UX architecture only — no Trading / Gold Mind math / Risk / Recovery / Execution / AI decision changes

---

## 1. Design principle (non-negotiable)

> Beautiful is required. Functionality always comes first.  
> A trader must understand complete account status within a few seconds — without decorative noise.

| Priority | Meaning |
|----------|---------|
| 1 | Clarity of account & risk state |
| 2 | Fast navigation to positions / history / config |
| 3 | Consistent brand & components |
| 4 | Motion / ornament (optional, rare) |

---

## 2. Foundations

| Layer | Spec location |
|-------|---------------|
| Color | `COLOR_GUIDELINES.md` |
| Type | §3 below |
| Spacing | §4 |
| Radius | §5 |
| Components | `UI_COMPONENT_LIBRARY.md` |
| Layout | `DASHBOARD_LAYOUT.md` |
| Navigation | `NAVIGATION_STRUCTURE.md` |
| Breakpoints | `RESPONSIVE_GUIDE.md` |

---

## 3. Typography

| Role | Guidance | Notes |
|------|----------|-------|
| Brand / About | Premium display or refined serif (official kit when supplied) | Never invent logo letterforms |
| UI primary | Clean modern sans, high legibility at 12–14px dense data | Trading density allowed |
| UI secondary | Same family, lighter weight / muted color | Labels, captions |
| Numeric / P&L | Tabular lining figures preferred | Align columns |
| Logs / diagnostics | Monospace | Dev/support surfaces only |

**Scale (guidance)**

| Token | Size | Use |
|-------|------|-----|
| `text-xs` | 11px | Badges, meta |
| `text-sm` | 12–13px | Tables, widgets |
| `text-md` | 14px | Body, nav |
| `text-lg` | 16–18px | Section titles |
| `text-xl` | 20–24px | Page titles |
| `text-brand` | 28px+ | Brand moments only (wizard, about) |

---

## 4. Spacing scale

Base unit: **4px**

| Token | Value | Use |
|-------|------:|-----|
| `space-1` | 4 | Tight icon gaps |
| `space-2` | 8 | Inline controls |
| `space-3` | 12 | Compact widget padding |
| `space-4` | 16 | Default panel padding |
| `space-5` | 24 | Section gaps |
| `space-6` | 32 | Page margins (comfortable) |
| `space-8` | 48 | Hero commercial only |

**Trader views:** denser (`space-3`/`space-4`).  
**Commercial / wizard:** calmer (`space-5`/`space-6`).

---

## 5. Border radius

| Token | Value | Use |
|-------|------:|-----|
| `radius-none` | 0 | Charts, terminal chrome (optional) |
| `radius-sm` | 4 | Inputs, badges |
| `radius-md` | 6–8 | Buttons, cards |
| `radius-lg` | 12 | Modals (commercial shell) |

Avoid pill-everywhere aesthetics. Prefer restrained enterprise corners.

---

## 6. Elevation & surfaces

| Level | Role |
|-------|------|
| Base | App background (Premium Black) |
| Panel | Left nav, side panels |
| Elevated | Cards / widgets on workspace |
| Overlay | Dialogs, tooltips, menus |
| Focus ring | Gold or high-contrast outline for keyboard |

Shadows: soft, low opacity — never multi-layer neon glow.

---

## 7. Iconography

| Rule | Spec |
|------|------|
| Style | Line / duotone restrained; 16 / 20 / 24px |
| Color | Ivory default; Gold for active/selected; semantic colors for status only |
| Source | Official icon set under `Commercial/Assets/` when provided |
| Never | Emoji as primary UI icons |

---

## 8. Motion

| Allowed | Forbidden |
|---------|-----------|
| Status fade-in (≤200ms) | Continuous decorative animation |
| Panel collapse expand | Parallax / particle backgrounds |
| Skeleton shimmer (subtle) | Confetti / hype |

---

## 9. Themes

| Theme | Status |
|-------|--------|
| Dark (Premium Black) | **Primary — ship first** |
| Light | Future — same tokens, inverted surfaces |
| High Contrast | Accessibility overlay — see Color Guidelines |

---

## 10. Alignment with frozen Core UI

This design system guides:

- Commercial shell / website / portal  
- Future Professional dashboard chrome  
- Welcome Wizard / installer  

It does **not** authorize refactor of frozen Dashboard engine behavior or remapping trade authority. Implementation of widgets remains observe/advise/display only.

---

*End of DESIGN_SYSTEM.md*
