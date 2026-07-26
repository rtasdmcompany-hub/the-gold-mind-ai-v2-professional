# STORE_COMPLIANCE_REPORT.md

**Phase:** 10 · Sprint 7  
**UI:** `/portal/admin/mql5-compliance`  
**CLI:** `npm run mql5:sprint7`  

---

## Requirements reviewed

| Requirement | Outcome |
|-------------|---------|
| No prohibited marketing language | PASS (listing + scan) |
| No unrealistic profit guarantees | PASS |
| No external payment instructions | PASS (Market package) |
| No external activation requirements | PASS (Market license only) |
| No misleading screenshots | WARN — live captures pending |
| No prohibited links in product | WARN — Core `#property link` read-only finding |
| Store-compliant package | PASS — Market one-click, no Website installer |
| Correct copyright | PASS |

## Scan scope

- `Experts/TheGoldMindAI_Professional.mq5` (**read-only**)  
- `Commercial/MarketEdition/Listing/**`  
- `Commercial/MarketEdition/Package/**`  

Website portal / PaymentPort are **out of Market package scope** by design.
