# COLOR_GUIDELINES.md

**Phase 8 · Sprint 4**  
**Extends:** `BRAND_STANDARD.md` (Sprint 1)  
**Primary theme:** Dark · Premium Black · Metallic Gold

---

## 1. Official primary palette

| Name | Token | Hex | Role |
|------|-------|-----|------|
| Premium Black | `--gm-black-950` | `#0B0B0C` | App background |
| Surface Black | `--gm-black-900` | `#141416` | Panels / nav |
| Elevated Black | `--gm-black-800` | `#1C1C1F` | Cards / widgets |
| Border Subtle | `--gm-border` | `#2A2A2E` | Dividers |
| Metallic Gold | `--gm-gold-500` | `#C6A75E` | Brand accent / CTA / active nav |
| Gold Highlight | `--gm-gold-300` | `#E1C57A` | Hover / focus accent |
| White / Ivory | `--gm-ivory-100` | `#F3EFE6` | Primary text |
| Muted Ivory | `--gm-ivory-300` | `#C9C2B4` | Secondary text |
| Success Green | `--gm-success` | `#2F6B4F` | Healthy / profit positive (restrained) |
| Warning Amber | `--gm-warning` | `#C4922A` | Caution / approaching limits |
| Error Red | `--gm-danger` | `#B33A3A` | Critical / loss / blocked |
| Information Blue | `--gm-info` | `#3A6B8C` | Neutral informational |

---

## 2. Semantic usage rules

| Semantic | Use for | Do not use for |
|----------|---------|----------------|
| Gold | Brand, primary actions, selected state | Error, profit (avoid gold = money confusion) |
| Success green | Ready, connected, positive P&L | Marketing decoration |
| Amber | Margin warn, news risk, grace license | Everyday labels |
| Red | Hard fail, SL hit alerts, expired license | Decorative accents |
| Blue | Tips, info toasts, neutral status | Primary brand |

**P&L:** Prefer success/danger with tabular numbers — not rainbow heatmaps in the primary chrome.

---

## 3. Theme modes

### Dark (Primary)
- Background stack: 950 → 900 → 800  
- Text: ivory on black  
- Accents: metallic gold sparingly (≤ ~10% of chrome)

### Light (Future)
| Token role | Guidance |
|------------|----------|
| Background | Near-white warm neutral (not cream cliché) |
| Surface | Soft gray panels |
| Text | Near-black |
| Gold | Same metallic gold for brand continuity |
| Borders | Slightly stronger for definition |

### High Contrast Accessibility
- Boost text contrast to WCAG AA minimum (prefer AAA for body where feasible)  
- Thicker focus rings  
- Do not rely on color alone for status — pair with icon + label  
- Disable low-contrast gold-on-black for small text; use ivory + gold underline for links

---

## 4. Charts & data visualization

| Series | Guidance |
|--------|----------|
| Equity | Ivory / soft gold line |
| Drawdown | Amber → Red scale |
| Volume/secondary | Muted slate (not competing with gold) |
| Grid | Very low-contrast borders |

Avoid purple “AI” gradients and neon crypto palettes (brand lock).

---

## 5. Status badge colors

| Status | Background | Text |
|--------|------------|------|
| Active / OK | Success @ 20% opacity | Success / ivory |
| Warning | Amber @ 20% | Amber / ivory |
| Error | Danger @ 20% | Danger / ivory |
| Info | Info @ 20% | Info / ivory |
| License | Gold @ 15% | Gold |

---

## 6. Do / Don’t

| Do | Don’t |
|----|-------|
| One gold accent hierarchy | Gold + purple + cyan competing |
| Semantic colors for meaning | Color as decoration only |
| Consistent token names across portal + app | Ad-hoc hex per screen |
| Official logos only | Recolor logo arbitrarily |

---

*End of COLOR_GUIDELINES.md*
