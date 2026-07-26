# PAYMENT_ABSTRACTION.md

**Phase 8 · Sprint 3**  
**Goal:** Swap payment providers without rewriting licensing logic  
**Initial targets:** Paddle · PayPal · Future providers

---

## 1. Principle

```
Customer Portal / Checkout UI
        ↓
Payment Port (interface)
        ↓
┌─────────────┬─────────────┬──────────────┐
│ PaddleAdapter│ PayPalAdapter│ FutureAdapter│
└─────────────┴─────────────┴──────────────┘
        ↓
Normalized Payment Events
        ↓
Subscription Service → License Service
```

Licensing must depend on **normalized events**, not provider SDKs.

---

## 2. Payment Port (logical interface)

| Operation | Intent |
|-----------|--------|
| `CreateCheckout(plan, customer)` | Start purchase |
| `CancelSubscription(provider_ref)` | Stop auto-renew |
| `ChangePlan(provider_ref, new_plan)` | Upgrade/downgrade |
| `GetInvoice(provider_ref)` | Portal invoices |
| `VerifyWebhook(signature, payload)` | Secure inbound events |

---

## 3. Normalized event model

| Event | Meaning |
|-------|---------|
| `payment.succeeded` | Funds captured |
| `payment.failed` | Attempt failed |
| `subscription.created` | Recurring started |
| `subscription.renewed` | Period extended |
| `subscription.cancelled` | Auto-renew off / cancelled |
| `subscription.past_due` | Payment retrying |
| `refund.created` | Refund / chargeback-related |
| `dispute.opened` | Dispute workflow |

Each event includes: `provider`, `provider_event_id`, `customer_id`, `plan_code`, `amount`, `currency`, `occurred_at`.

---

## 4. Provider notes (planning)

### Paddle
- Strong SaaS checkout / tax handling  
- Webhook-driven entitlements  
- Good fit for Website Professional  

### PayPal
- Familiar consumer checkout  
- Map IPN/webhooks → normalized events  
- Careful reconciliation for renewals  

### Future providers
- Stripe, local PSPs, etc.  
- Implement new Adapter only — no License Service rewrite  

---

## 5. Idempotency & reconciliation

- Dedupe on `provider_event_id`  
- Daily reconciliation job: provider vs internal entitlements  
- Never issue duplicate licenses for the same successful payment  

---

## 6. Hard boundary

Payment success grants **commercial entitlement**.  
It does **not** authorize trade execution changes.

---

*End of PAYMENT_ABSTRACTION.md*
