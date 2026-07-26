# THE GOLD MIND — Release Notes RC-2

**Version:** 2.0.0-rc.2  
**Build:** 21082  
**Date:** 2026-07-26  
**Core:** Certified unchanged (SHA-256 `75002e46…a033ce`)

---

## Summary

RC-2 packages the Phase 9 commercial platform for executive certification:

- Shared certified Core Trading Engine (frozen)
- Website Professional Edition: Customer Portal, licensing, billing, installer, auto-update, cloud, admin console
- MQL5 Market Edition: compliance shell + shared Core (Market billing independent)

---

## Website Professional — included

- Customer Portal (licenses, devices, billing, downloads, updates, support)
- PaymentPort (Paddle primary · PayPal secondary · Sandbox)
- License / subscription / device engines
- Windows installer + secure updater (SHA-256 · rollback)
- Cloud API gateway · health · audit · Upstash-ready cache
- Enterprise Admin Console (RBAC · BI · support · audit center)

---

## MQL5 Market — included

- Market edition shell & compliance checklist
- Same certified Core (no Website payment/portal dependency)

---

## Known notes (non-critical for RC-2)

- Live Paddle/PayPal production credentials env-gated (sandbox OK for RC-2)
- Authenticode Stable signing pending Owner certificate
- Legal policy content (Privacy/Terms/Refund/Cookie) required before unrestricted public launch
- 2FA enrollment architecture ready; enforcement pending
- Formal Jest/e2e suite deferred (RC-2 harness + tsc PASS)

---

## Upgrade / install

```powershell
cd Commercial\Installer\Professional\scripts
.\Install-TheGoldMindProfessional.ps1
.\Update-TheGoldMindProfessional.ps1 -PortalBase <portal-url> -Apply
```

Portal: `Commercial/CustomerPortal/web` → `npm run dev`  
Validate: `npm run validate:rc2`

---

## Isolation guarantee

Commercial failures (payment, cloud, portal) do **not** stop local Trading Engine operation.  
RC-2 does **not** modify Strategy, Risk, Recovery, Order Execution, Magic Number, or Trade Calculations.
