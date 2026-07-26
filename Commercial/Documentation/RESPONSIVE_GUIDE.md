# RESPONSIVE_GUIDE.md

**Phase 8 · Sprint 4**  
**Goal:** No clipping, no overlapping, readable at all supported resolutions

---

## 1. Supported resolutions

| Resolution | Class | Nav default | Widget columns |
|------------|-------|-------------|----------------|
| 1366×768 | Laptop compact | Collapsed | 2 |
| 1600×900 | Laptop+ | Expanded | 2–3 |
| 1920×1080 | Desktop standard | Expanded | 3 |
| 2560×1440 | QHD | Expanded | 3–4 |
| 3840×2160 (4K) | UHD | Expanded | 4 + max content width |

---

## 2. Layout rules

| Rule | Spec |
|------|------|
| Min workspace width | Never crush tables below readable ~640px — use horizontal scroll inside table region if needed |
| Panels | Stack vertically when width insufficient (Trading → Statistics → Portfolio) |
| Footer | Single line truncate with tooltip; never cover content |
| Modals | Max-width + scroll body; stay within viewport padding 16–24px |
| Charts | Fluid width; fixed aspect or min-height to avoid collapse |

---

## 3. Breakpoint tokens (guidance)

| Token | Min width |
|-------|----------:|
| `bp-compact` | 1280 |
| `bp-standard` | 1600 |
| `bp-wide` | 1920 |
| `bp-ultra` | 2560 |

MT5 chart-object UIs may approximate these via DPI / canvas size checks rather than CSS media queries.

---

## 4. Density modes

| Mode | When |
|------|------|
| Compact | 1366×768 — smaller padding, condensed tables |
| Comfortable | 1920×1080 default |
| Spacious | 4K — increase type slightly; cap measure width for readability |

User preference override (future): Compact / Comfortable.

---

## 5. Clipping prevention checklist

- [ ] Left nav collapse never hides active page title (move to top)  
- [ ] Widget grid uses consistent gutters (`space-3`/`space-4`)  
- [ ] Long broker names truncate with ellipsis + tooltip  
- [ ] Notification toasts stack within safe inset  
- [ ] No absolute-positioned gold ornaments over data  
- [ ] 125% / 150% OS scaling smoke-tested  

---

## 6. 4K guidance

- Do not merely upscale pixel-perfect 1080 layout until unreadable gaps appear  
- Cap primary content column (~1600–1800px) centered or left-aligned with nav  
- Keep tabular data density — traders want data, not empty luxury void  

---

*End of RESPONSIVE_GUIDE.md*
