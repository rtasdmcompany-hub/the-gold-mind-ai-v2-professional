# MQL5_MARKET_READINESS.md

**Phase 8 · Sprint 9**  
**Edition:** THE GOLD MIND MARKET  
**Nature:** Dedicated Market review — **recommendations only**  
**Extends:** `Commercial/MarketEdition/Compliance/MQL5_COMPLIANCE_CHECKLIST.md`

---

## 1. Compliance verification (review)

| Requirement | Status | Recommendation |
|-------------|--------|----------------|
| No external payment prompts | Design intent READY | Audit UI/copy before upload — zero Paddle/PayPal CTAs in Market build |
| No external activation requirements | Design intent READY | Compile-time exclude Website license server; Market activation only |
| No prohibited advertising | IN PROGRESS | Strip guaranteed-profit / competitor attacks; evidence-based claims only |
| No policy violations | IN PROGRESS | Re-read current MQL5 Market rules at upload time (rules change) |
| Correct screenshots | NOT STARTED | Capture Market build only — no Portal/license screens |
| Professional description | IN PROGRESS | Short honest scope; Core sole execution; risk disclosure |
| Installation guide | IN PROGRESS | Market-specific attach steps; no Website installer dependency |
| Version history | IN PROGRESS | Align with shared Core SemVer tag |
| Market packaging | IN PROGRESS | Lightweight; Market-legal dependencies only |
| Compliance checklist | READY (design) | Execute checklist on RC before publish |

---

## 2. Hard exclusions for Market Edition

- Website portal login to run EA  
- External license key dialogs  
- Auto-updater competing with Market updates  
- Illegal DLL / web license locks  
- Selling Professional-only features in Market description  

---

## 3. Listing package (prepare)

| Asset | Spec |
|-------|------|
| Title | THE GOLD MIND MARKET |
| Short description | Premium systematic trading assistant — Market-compliant |
| Full description | Features actually in Market build + risk text |
| Screenshots | Dashboard glance · settings · about (Market chrome) |
| Version | Same Core `MAJOR.MINOR.PATCH` as Website sibling release |

---

## 4. Pre-publish recommendations

1. Build `market-stable` profile from **same Core tag** as Professional  
2. Automated scan for URLs / payment / activate strings  
3. Fresh screenshots from clean demo  
4. Second-person compliance review (not the author)  
5. Support path: Market comments + email/KB (no forced portal)  

---

## 5. Verdict (architecture)

Market Edition is **architecturally separable** and packaging metadata is aligned to **Core Build 417** (same SHA as Website Professional **1.1.0**).

**Packaging READY** for MetaQuotes submission prep (MANIFEST / listing / Core tag updated 2026-08-25).

**Upload READY only after:** fresh Market-build screenshots, live MQL5 rules re-read, and compile/upload of the certified `.ex5` in MetaEditor Market product form — not the Website installer ZIP.


---

*End of MQL5_MARKET_READINESS.md*
