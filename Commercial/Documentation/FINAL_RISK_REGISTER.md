# FINAL_RISK_REGISTER.md

**Launch risk score (higher = safer):** 64  
**Critical open:** 0 · **High open:** 2

| ID | Severity | Title | Likelihood | Target | Status |
|----|----------|-------|------------|--------|--------|
| R-LEGAL | High | Legal pack drafts not counsel-approved | High | Open Stable | open |
| R-BRAND | High | BC-BRAND Owner asset pack incomplete | Medium | Open Stable | open |
| R-PSP | High | Live PSP credentials not configured | High | Open Stable | accepted |
| R-AUTHENTICODE | Medium | Authenticode Stable signing pending | Medium | Global Commercial | open |
| R-MQL5-SHOTS | Medium | MQL5 live MT5 screenshots pending | High | Global Commercial | open |
| R-CORE-SIGN | Medium | Owner Core attestation signature pending | Low | Controlled Launch | open |
| R-EMAIL | Medium | Transactional email provider optional in RC | Medium | Open Stable | accepted |
| R-2FA | Low | Admin 2FA enrollment not enforced | Low | Post-launch | accepted |

## Details

### R-LEGAL — Legal pack drafts not counsel-approved
- **Business:** Regulatory / trust risk if open marketing before sign-off
- **Technical:** None on Core; commercial pages only
- **Mitigation:** Keep invite-only; publish counsel-approved Privacy/Terms/Refund/Risk before open Stable

### R-BRAND — BC-BRAND Owner asset pack incomplete
- **Business:** Inconsistent public brand presentation
- **Technical:** None
- **Mitigation:** Owner supplies Commercial/Assets per LAUNCH_ASSETS_GUIDE; Market icons already staged

### R-PSP — Live PSP credentials not configured
- **Business:** Cannot take unrestricted paid public customers via live checkout
- **Technical:** Sandbox PaymentPort remains for Controlled Launch
- **Mitigation:** Wire Paddle/PayPal live secrets or Owner written sandbox waiver for invite cohort

### R-AUTHENTICODE — Authenticode Stable signing pending
- **Business:** Windows SmartScreen warnings for some customers
- **Technical:** Installer SHA-256 verification still enforced
- **Mitigation:** Complete Authenticode before Global Commercial; RC checksum path OK for Controlled Launch

### R-MQL5-SHOTS — MQL5 live MT5 screenshots pending
- **Business:** Market upload blocked until gallery complete
- **Technical:** Website Edition unaffected
- **Mitigation:** Capture per Assets/Market/Screenshots/CAPTURE_PLAN.md before Market Stable upload

### R-CORE-SIGN — Owner Core attestation signature pending
- **Business:** Governance completeness
- **Technical:** SHA-256 file certification already present and verified
- **Mitigation:** Owner signs RC2_CORE_CERTIFICATION statement

### R-EMAIL — Transactional email provider optional in RC
- **Business:** Missed purchase/activation emails in prod if unset
- **Technical:** Outbox path exists
- **Mitigation:** Configure Resend/SendGrid/SMTP before paying cohort expands

### R-2FA — Admin 2FA enrollment not enforced
- **Business:** Elevated admin account risk
- **Technical:** Architecture present; idle timeout active
- **Mitigation:** Enroll TOTP/WebAuthn for super_admin before Global Commercial

