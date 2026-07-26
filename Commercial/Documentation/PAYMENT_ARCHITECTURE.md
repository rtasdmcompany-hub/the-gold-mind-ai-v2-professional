# PAYMENT_ARCHITECTURE.md

**Phase:** 9 — Commercial Implementation & Launch Hardening  
**Sprint:** 4 — Billing & Subscription  
**Edition:** THE GOLD MIND PROFESSIONAL (Website only)  
**Code root:** `Commercial/CustomerPortal/web/src/server/billing/`  
**Isolation:** No Core Trading Engine · No MQL5 Market checkout coupling

---

## Principle

Business logic **never** depends on a specific payment service provider (PSP).  
All commercial flows resolve a `PaymentPort` and consume **normalized** events only.

```
Portal / API Checkout
        │
        ▼
  getPaymentPort(provider?)
        │
        ├── paddle   (primary)
        ├── paypal   (secondary)
        ├── sandbox  (local / MVP)
        └── stripe   (future stub)
        │
        ▼
  CheckoutSession { checkoutUrl, checkoutId, plan, amount… }
```

```
PSP → POST /api/billing/webhooks/{provider}
        │
        ▼
  PaymentPort.verifyWebhook(headers, rawBody)   ← HMAC / signature
        │
        ▼
  NormalizedPaymentEvent
        │
        ▼
  processNormalizedEvent()   ← idempotent · retry-safe
        │
        ├── Invoice + Payment ledger
        ├── Billing subscription
        ├── License assignment (Licensing Engine)
        └── Commercial email outbox
```

---

## PaymentPort contract

| Method | Purpose |
|--------|---------|
| `createCheckout(CheckoutRequest)` | Start hosted / sandbox checkout |
| `cancelSubscription(providerRef)` | Provider-side cancel (when credentials present) |
| `verifyWebhook(headers, rawBody)` | Authenticate + map to `NormalizedPaymentEvent` |

Registry: `payment-port.ts` · Adapters: `providers.ts`

---

## Providers

| Provider | Role | Env |
|----------|------|-----|
| **Paddle** | Primary | `PADDLE_VENDOR_ID`, `PADDLE_PRICE_ID`, `PADDLE_WEBHOOK_SECRET` |
| **PayPal** | Secondary | `PAYPAL_CLIENT_ID`, `PAYPAL_WEBHOOK_ID` / `PAYPAL_WEBHOOK_SECRET` |
| **Sandbox** | Local / MVP | `SANDBOX_WEBHOOK_SECRET` |
| **Stripe** | Future stub | Registered; `verifyWebhook` returns null until wired |

`PAYMENT_PRIMARY_PROVIDER` (default `paddle`) · `PAYMENT_FORCE_SANDBOX=true` forces sandbox.

Without live credentials, Paddle/PayPal adapters fall back to the sandbox hosted checkout page so Website Edition development continues without blocking on PSP accounts.

---

## Plans (Website Edition catalog)

| Plan | Amount | Interval |
|------|--------|----------|
| Trial | USD 0.00 | 14d |
| Monthly | USD 99.00 | month |
| Yearly | USD 899.00 | year |
| Lifetime | USD 2,499.00 | once |

Defined in `util.ts` → `PLAN_CATALOG`.

---

## Normalized events

| Type | Commercial effect |
|------|-------------------|
| `payment.succeeded` | Invoice · payment · license · emails |
| `subscription.created` | Same as succeeded (trial/create path) |
| `subscription.renewed` | renewLicense · receipt |
| `payment.failed` / `subscription.past_due` | Ledger fail · past_due · failure email |
| `refund.created` | Refund ledger · invoice refunded |
| `subscription.cancelled` | Cancel status · confirmation email |
| `dispute.opened` | Chargeback / dispute ledger |

---

## Edition boundary

| Edition | Payment model |
|---------|---------------|
| **Professional (Website)** | This PaymentPort + Customer Portal |
| **Market (MQL5)** | MQL5 Market billing only — **must not** import this module |

Constant: `WEBSITE_EDITION_ONLY` in `util.ts`.

Financial failure **never** alters Core Trading Engine, Strategy, Risk, Recovery, Order Execution, or Magic Number logic.

---

*End of PAYMENT_ARCHITECTURE.md*
