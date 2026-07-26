# SUBSCRIPTION_WORKFLOW.md

**Phase 8 · Sprint 3**  
**Plans:** Trial · Monthly · Yearly · Lifetime (+ optional maintenance)  
**Rule:** Subscription state machines are commercial — not trading logic

---

## 1. Workflow catalog

### New Purchase
```
Select plan → Checkout (Payment Abstraction) → Payment verified
  → License generated → Entitlement active (or pending activation)
  → Email + Portal “My Licenses” → Customer activates device
```

### Renewal (auto)
```
Provider invoices → Payment success webhook
  → Subscription period extended → License expiry extended
  → Receipt email → Portal Payment History updated
```

### Renewal (manual / reminder)
```
T-30/T-14/T-7/T-1 reminders → Customer renews in Portal
  → Same as renewal success path
```

### Upgrade (e.g. Monthly → Yearly, or add seats)
```
Portal Upgrade → Proration via provider (if supported)
  → Entitlement updated → Confirmation email
```

### Downgrade
```
Portal Downgrade request → Effective at period end (recommended)
  → Entitlement schedule updated → Confirmation
```
Avoid immediate feature yank mid-cycle unless policy requires.

### Cancellation
```
Cancel auto-renew → Access remains until period end
  → Status cancelled_pending_expiry → Then expired
```

### Expired License
```
Status expired → Commercial shell limited
  → Reactivate / repurchase CTAs
  → Core trading policy remains Owner-defined; licensing still must not patch Core
```

### Grace Period
```
Payment fail or clock skew → grace status for N days
  → Warning banners + emails
  → Resolve payment → active
  → Else expired
```

---

## 2. State machine (subscription)

| State | Next typical states |
|-------|---------------------|
| `trialing` | `active`, `expired`, `converted` |
| `active` | `past_due`, `cancelled`, `expired`, `upgraded` |
| `past_due` | `grace`, `active`, `expired` |
| `grace` | `active`, `expired` |
| `cancelled` | `expired` (at period end) |
| `expired` | `active` (on repurchase) |

---

## 3. Lifetime specifics

- No recurring subscription object required for base lifetime SKU  
- Optional `maintenance_subscription` can attach for updates/support tiers  
- Lifetime still participates in device limits and ToS revocation policy  

---

## 4. Customer communications

| Event | Channel |
|-------|---------|
| Purchase success | Email + Portal |
| Renewal upcoming | Email |
| Payment failed | Email + Portal banner |
| Grace started | Email + Portal |
| Expired | Email + Portal |
| Upgrade/downgrade | Email |

Tone: calm, premium, precise — no hype.

---

## 5. Internal ops

- Audit every transition  
- Support agents can view (not silently invent) entitlements  
- Chargeback → suspend / revoke policy path  

---

*End of SUBSCRIPTION_WORKFLOW.md*
