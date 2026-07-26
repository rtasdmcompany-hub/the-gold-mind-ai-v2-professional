# DEVICE_MANAGEMENT.md

**Phase 8 · Sprint 3**  
**Context:** THE GOLD MIND PROFESSIONAL licensing seats  
**Rule:** Device identity is for entitlement enforcement — not remote trading control

---

## 1. Capabilities

| Capability | Description |
|------------|-------------|
| Active Devices | List devices bound to a license |
| Device Rename | Customer-friendly label (e.g. “VPS-London”) |
| Device Deactivation | Free a seat; invalidate local lease on next validate |
| Device Transfer | Deactivate A + activate B under policy |
| Maximum Device Limit | Enforced per license / plan |

---

## 2. Device record

| Field | Purpose |
|-------|---------|
| `device_id` | Stable internal id |
| `fingerprint_hash` | Hashed device fingerprint (see Security Model) |
| `display_name` | User-editable |
| `first_seen_at` / `last_seen_at` | Audit |
| `status` | `active` · `deactivated` · `pending` |
| `app_version` | Optional support metadata |

---

## 3. Seat policy examples (configurable)

| Plan | Typical max devices |
|------|---------------------|
| Trial | 1 |
| Monthly | 1–2 |
| Yearly | 1–3 |
| Lifetime | Policy-defined (e.g. 2) |
| Enterprise seat pack | Purchased seats |

Exact numbers are commercial policy — architecture supports configuration.

---

## 4. Customer Portal UX

**Device Management page:**
- Table: Name · Last seen · Status · Actions  
- Actions: Rename · Deactivate · Transfer help  
- When at limit: “Deactivate a device to activate on a new PC”  

---

## 5. Transfer workflow

```
Request transfer
  → Soft warning (what will happen)
  → Deactivate source device (or auto on new activation if policy allows)
  → Activate destination fingerprint
  → Audit event recorded
```

Anti-abuse: rate-limit transfers; flag suspicious churn for Support review.

---

## 6. What device management never does

- No remote wipe of MT5 accounts  
- No remote trade close  
- No pushing strategy parameters to Core  
- No reading customer broker passwords  

---

*End of DEVICE_MANAGEMENT.md*
