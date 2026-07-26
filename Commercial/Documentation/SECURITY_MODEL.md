# SECURITY_MODEL.md

**Phase 8 · Sprint 3**  
**Scope:** Licensing · Portal · Devices · Sessions  
**Non-scope:** Changing Core trading cryptography or strategy math

---

## 1. Threat model (commercial)

| Threat | Mitigation direction |
|--------|----------------------|
| Key sharing beyond seats | Device limits + fingerprint + transfer rate limits |
| Token forgery | Asymmetric signatures / HMAC with rotated secrets |
| Replay | Nonce + expiry on activation tokens / leases |
| Tampering local license file | Integrity MAC; fail closed to grace/expired UX |
| Webhook spoofing | Provider signature verification |
| Session hijack | Secure cookies, rotation, logout-all |
| Support social engineering | Least-privilege agent roles + audit |

---

## 2. License encryption & tokens

| Artifact | Spec |
|----------|------|
| License key | High-entropy; displayed masked in UI |
| Activation token | Short-lived, signed, bound to customer + license |
| Local lease | Encrypted at rest on device; includes expiry + entitlements |
| Server secrets | HSM/KMS or hardened secret store (ops standard) |

---

## 3. Secure device fingerprint

| Principle | Spec |
|-----------|------|
| Collect | Stable hardware/OS signals appropriate to Windows desktop |
| Store | **Hash only** (`fingerprint_hash`) — minimize PII |
| Bind | License seat ↔ hash |
| Privacy | No broker passwords; document what’s collected in Privacy Policy |

---

## 4. Offline grace mode

| Rule | Spec |
|------|------|
| When | No internet for revalidation |
| Allow | Continue commercial shell for configured grace window if last lease valid |
| UX | Clear “Offline grace — reconnect to revalidate” |
| End | Require online validation; move to expired/limited |
| Never | Grace must not invent new trade powers |

---

## 5. Anti-tamper strategy (licensing client)

- Signed application packages when available  
- Detect obvious lease file surgery → invalidate lease  
- Obfuscation is not primary control — **server validation is**  
- Critical actions (activate, free seat) require server authority  

---

## 6. License validation workflow

```
App start / timer
  → Read local lease
  → If expired locally → attempt online validate
  → Online: send device hash + license id + client nonce
  → Server verifies signature, status, seats
  → Return new signed lease OR denial reason
  → Update local store
  → Emit portal-visible status only (no Core mutation)
```

---

## 7. Session management (Portal)

| Control | Spec |
|---------|------|
| Login | Credential check + optional MFA later |
| Session TTL | Absolute + idle timeouts |
| Refresh | Rotating refresh tokens if applicable |
| Logout | Invalidate server session |
| Logout all devices | Portal security action |
| Audit | Login success/fail, password change |

---

## 8. Compliance alignment

- Privacy Policy must describe device fingerprinting  
- Payment data stays with Paddle/PayPal (PCI scope reduction)  
- Audit logs retained per policy  

---

*End of SECURITY_MODEL.md*
