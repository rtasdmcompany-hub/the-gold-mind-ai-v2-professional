# UX_RECOMMENDATIONS.md

**Phase 8 · Sprint 4**  
**Nature:** Recommendations only — no Core behavior changes  
**Inputs:** Enterprise UI reviews, Sprint remapping feedback, Brand Standard

---

## 1. First impression (0–10 seconds)

| Issue | Recommendation |
|-------|----------------|
| Sprint certification widgets feel internal | Pin a **stable commercial widget taxonomy** (Account, Risk, Market, License) |
| Brand weak if nav removed | Keep wordmark + gold accent in top chrome always |
| Demo vs Live ambiguous | Persistent Demo/Live badge in top nav |

---

## 2. Reduce clicks

| Journey | Target |
|---------|--------|
| See open positions | ≤1 click from Dashboard (or visible count widget → click) |
| Activate license | Wizard page or License nav — not buried |
| Check daily P&L | Visible on Dashboard home without drill-down |
| Support | Support nav + footer link |

Prefer deep links from widgets over nested menus.

---

## 3. Navigation improvements

- Group TRADE / INSIGHT / RESEARCH / SYSTEM (see Navigation Structure)  
- Collapse on small screens by default  
- Remember last section  
- Disable unavailable edition features visibly (tooltip: “Professional feature”)  

---

## 4. Readability

- Tabular figures for money  
- Consistent date/time format  
- Muted secondary labels; one primary number per widget  
- Avoid all-caps walls of text  
- Line length: don’t stretch paragraphs across ultrawide  

---

## 5. Accessibility

- Keyboard path for primary nav  
- Focus rings meeting contrast  
- Status = color + icon + text  
- High Contrast theme path  
- Respect reduced-motion OS preference  

---

## 6. Consistency

| Do | Don’t |
|----|-------|
| Shared button / badge / dialog specs | One-off styles per Phase module |
| Customer language titles | “Sprint 9 EOC remap” labels |
| Same gold for active states everywhere | Random accent per panel |

---

## 7. Responsiveness

- Follow `RESPONSIVE_GUIDE.md` matrix  
- Tables scroll internally before overlapping nav  
- Test 1366×768 as minimum professional laptop  

---

## 8. Cognitive load

Dashboard home should answer:

1. Am I safe on margin?  
2. Am I up/down today?  
3. What’s open?  
4. Is the platform/license healthy?  

Defer research labs (backtest/opt) behind Research group — powerful, not first viewport clutter.

---

## 9. Commercial shell vs Core

| UX may | UX must not |
|--------|-------------|
| Hide advanced panels by edition | Change lot size / SL / recovery |
| Improve labels and layout maps | Remap Magic isolation |
| Gate downloads / license UI | Imply AI places trades |

---

## 10. Priority backlog (implementation later)

1. Freeze commercial Dashboard IA  
2. Implement design tokens in shell  
3. Collapse nav + responsive grid  
4. Empty/loading states everywhere  
5. Light theme (after dark polish)  

---

*End of UX_RECOMMENDATIONS.md*
