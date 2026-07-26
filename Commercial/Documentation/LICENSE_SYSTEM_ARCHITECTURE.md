# LICENSE_SYSTEM_ARCHITECTURE.md

**Phase 8 · Sprint 3**  
**Edition:** THE GOLD MIND PROFESSIONAL (Website)  
**Owner:** RTAS Group of Companies · RTAS Digital Marketing Company  
**Rule:** Commercial licensing only — never modifies Trading / Risk / Strategy / Execution / Recovery

---

## 1. Purpose

Provide an enterprise-grade entitlement layer comparable to Microsoft 365 / Adobe / JetBrains / TradingView:

- Sell access to the **Professional commercial shell**
- Validate entitlement securely
- Manage devices and subscriptions
- **Never** become a second trade executor

---

## 2. License types

### 2.1 Trial License
| Attribute | Spec |
|-----------|------|
| Duration | Time-limited (e.g. 7 / 14 / 30 days — product configurable) |
| Mode | Optional Demo-recommended experience |
| Expiration | Automatic at `expires_at` |
| Devices | Strict low limit (typically 1) |
| Conversion | One-click upgrade to Monthly / Yearly / Lifetime |

### 2.2 Monthly Subscription
| Attribute | Spec |
|-----------|------|
| Billing | Recurring monthly |
| Renewal | Auto-renewal supported via payment provider webhooks |
| Validation | Online validation cadence + signed local token |
| Grace | Short grace after failed payment (see Security / Subscription docs) |

### 2.3 Yearly Subscription
| Attribute | Spec |
|-----------|------|
| Billing | Annual |
| Discount | Eligible vs monthly (commercial policy) |
| Reminders | T-30 / T-14 / T-7 / T-1 renewal reminders |
| Validation | Same token model as monthly |

### 2.4 Lifetime License
| Attribute | Spec |
|-----------|------|
| Activation | Permanent entitlement (no recurring bill for license itself) |
| Maintenance | Optional maintenance / updates plan (separable SKU) |
| Devices | Policy-defined max seats |
| Revocation | Only for fraud / ToS breach / chargeback policy |

---

## 3. Core entities

```
CustomerAccount
  └── Entitlement(s)
        ├── License (type, status, dates, seats)
        ├── Subscription (if recurring)
        ├── DeviceRegistration[]
        ├── Invoice[] / PaymentEvent[]
        └── FeatureFlags (edition capabilities — non-trading)
```

---

## 4. Activation flow (system view)

```
Purchase
  → Payment Verification (Payment Abstraction)
  → License Generation (License Service)
  → Customer Email (key + portal link)
  → License Activation (app / portal)
  → Device Registration
  → Activation Success
  → Dashboard Access (commercial shell)
```

Detailed customer UX: Sprint 2 `LICENSE_ACTIVATION_FLOW.md`  
This document owns **service architecture**.

---

## 5. License lifecycle states

| State | Meaning |
|-------|---------|
| `pending` | Generated, not activated |
| `active` | Valid entitlement |
| `grace` | Temporary post-expiry / payment fail |
| `expired` | No longer entitled |
| `suspended` | Admin / fraud hold |
| `revoked` | Permanently invalidated |
| `cancelled` | Subscription cancelled (may remain active until period end) |

---

## 6. Validation workflow (high level)

1. Client presents activation token + device fingerprint  
2. License Service verifies signature, expiry, seat count, status  
3. Returns signed lease (short-lived) + entitlements  
4. Client stores encrypted lease locally  
5. Periodic revalidation (online) / offline grace rules apply  
6. **No validation outcome may call trade APIs**

---

## 7. Separation from Core Trading Engine

| Licensing may | Licensing must never |
|---------------|----------------------|
| Gate commercial UI modules | Open/close/modify orders |
| Gate downloads / updates channel | Change SL/TP/risk |
| Gate portal features | Alter Magic isolation |
| Show “license inactive” banners | Patch Recovery / Strategy |

If license is inactive: commercial shell limited; Core policy remains Owner-defined separately and must still respect frozen Core boundaries.

---

## 8. Service components (logical)

| Service | Responsibility |
|---------|----------------|
| License Service | Issue, validate, revoke licenses |
| Subscription Service | Plans, renewals, upgrades |
| Device Service | Seats, rename, deactivate, transfer |
| Payment Adapter | Paddle / PayPal / future |
| Notification Service | Emails / portal announcements |
| Customer Portal API | Account UX backend |
| Audit Log | Entitlement & payment events |

---

*End of LICENSE_SYSTEM_ARCHITECTURE.md*
