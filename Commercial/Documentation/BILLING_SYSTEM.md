# BILLING_SYSTEM.md

**Phase:** 9 · Sprint 4  
**Edition:** THE GOLD MIND PROFESSIONAL (Website)  
**Portal:** `/portal/billing`  
**Store:** AES-256-GCM encrypted file `.data/billing/billing.enc`  
**Isolation:** Financial ledger independent of Core Trading Engine

---

## Billing Center surfaces

| Surface | Source | Notes |
|---------|--------|-------|
| Checkout | `CheckoutPanel` → `PaymentPort` | Trial · Monthly · Yearly · Lifetime |
| Current Subscription | `BillingSubscriptionRecord` | plan · status |
| Renewal Date | billing subscription | from license expiry / plan |
| Next Billing Date | billing subscription | omitted for lifetime |
| License Status | Licensing Engine | active / grace / etc. |
| Invoices & Receipts | `InvoiceRecord[]` | paid / open / void / refunded |
| Payment History | `PaymentRecord[]` | succeeded / failed / refunded / disputed |
| Email outbox | `EmailOutboxItem[]` | last customer notifications |

Related portal routes:

| Route | Role |
|-------|------|
| `/portal/billing` | Billing Center |
| `/portal/billing/checkout/sandbox` | Sandbox hosted checkout |
| `/portal/invoices` | Invoice list |
| `/portal/orders` | Successful payment / order history |
| `/portal/subscriptions` | Billing subs + license entitlements |

APIs:

| Method | Route |
|--------|-------|
| GET/POST | `/api/billing` |
| POST | `/api/billing/webhooks/[provider]` |
| GET | `/api/admin/billing` |

---

## Data model (billing store)

```
BillingStoreData
  invoices[]
  payments[]
  subscriptions[]
  processedWebhooks[]     ← idempotency keys
  webhookAudits[]         ← auth / outcome security log
  emails[]                ← transactional outbox
```

Edition tag: `Professional_Website`.

---

## Receipt vs invoice

- **Invoice** — commercial document for a plan purchase (links optional `licenseId`).
- **Receipt** — confirmation email + successful payment row in history.
- **Orders** page filters succeeded payments for customer-facing order history.

---

## Security

- Store encrypted at rest (AES-256-GCM).
- Secrets via env: `BILLING_STORE_SECRET` (or fallback chain documented in `store.ts`).
- Plaintext license keys appear only once in license-delivery email / sandbox UI — never on webhook HTTP responses.

---

## Non-goals (this sprint)

- Live Paddle Billing / PayPal Subscription SDK production wiring (URL + HMAC adapters ready; credentials env-gated).
- SMTP/SES transport (outbox + console log; transport is future).
- Any coupling to MQL5 Market commerce or Trading Engine runtime.

---

*End of BILLING_SYSTEM.md*
