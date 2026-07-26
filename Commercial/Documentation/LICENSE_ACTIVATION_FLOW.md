# LICENSE_ACTIVATION_FLOW.md

**Edition A — PROFESSIONAL (Website)**  
**Edition B — MARKET** (simplified; see bottom)  
**Rule:** Licensing is commercial entitlement only — never a trade executor

---

## Professional activation flow

```
Launch post-install / Wizard Page 3
   ↓
Enter License Key  OR  Sign In to Customer Portal
   ↓
Validate with RTAS license service
   ↓
Device Registration (fingerprint / device label)
   ↓
Activation Status = Active
   ↓
Entitlements applied (edition features)
   ↓
Continue Wizard
```

---

## UI states

| State | Customer sees | Next action |
|-------|---------------|-------------|
| Empty | Key field + Sign In | Enter credentials |
| Validating | Spinner · “Activating…” | Wait |
| Active | Green · device registered | Continue |
| Invalid key | Clear error | Recheck key / Support |
| Device limit | Explain seats | Manage devices in Portal |
| Offline | Grace policy message | Connect or continue if grace allows shell only |
| Expired | Renew CTA | Customer Portal subscriptions |

---

## Device registration (product rules)

- Show friendly device name (editable label)  
- Store registration timestamp  
- Allow portal-side revoke (Professional)  
- Do not require re-activation on every MT5 restart if token valid  

---

## Security & trust (commercial)

- HTTPS to license endpoints only  
- Never embed secrets in customer UI copy  
- Display RTAS Group of Companies as licensor  
- Failed attempts: rate-limit messaging + Support path  

---

## What activation does **not** do

- Does not open/close trades  
- Does not change SL/TP/risk  
- Does not bypass Magic isolation  
- Does not alter Recovery Engine  

---

## Market edition (B)

```
Market purchase → Market license bind → Activated → Continue
```

- Simple activation  
- No Website Portal dependency  
- MQL5 Market compliant  

---

*End of LICENSE_ACTIVATION_FLOW.md*
