# LICENSE_ENGINE_IMPLEMENTATION.md

**Phase:** 9 · Sprint 3  
**Location:** `Commercial/CustomerPortal/web/src/server/licensing/`  
**Rule:** Independent commercial service — **zero** Core Trading Engine dependency

---

## 1. Capabilities

| Type | Supported |
|------|-----------|
| Trial | Yes (14 days default) |
| Monthly | Yes (30 days) |
| Yearly | Yes (365 days) |
| Lifetime | Yes (no expiry) |

Metadata stored encrypted at rest (AES-256-GCM). Integrity MAC (HMAC-SHA256) per license.

---

## 2. Activation workflow

```
Purchase (createLicense)
  → License Generation (plaintext key once)
  → Customer Portal (masked list)
  → Activation Request (key + device fingerprint)
  → License Validation (status / seats / email bind)
  → Device Registration
  → Activation Complete (+ short-lived validation token)
```

Online validation: `validateLicenseOnline` with configurable grace (`LICENSE_GRACE_DAYS`, default 7).

---

## 3. APIs

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/licenses` | Customer licenses (public DTOs) |
| POST | `/api/licenses/actions` | create / activate / validate |
| GET/POST | `/api/devices` | list / rename / deactivate / transfer |
| GET | `/api/subscriptions` | subscription DTOs |
| GET | `/api/admin/licensing` | admin read-only lookup |

Server actions in `actions.ts` power Portal forms.

---

## 4. Isolation

- No MetaTrader / Experts / Risk / Recovery imports  
- Commercial failure cannot interrupt trading (separate process/service)  
- Client receives **masked** keys only after creation  

---

*End of LICENSE_ENGINE_IMPLEMENTATION.md*
