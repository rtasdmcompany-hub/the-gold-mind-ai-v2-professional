# SUBSCRIPTION_AUTOMATION.md

**Phase:** 9 · Sprint 4  
**Edition:** THE GOLD MIND PROFESSIONAL (Website)  
**Modules:** `billing-service.ts` · `webhook-processor.ts` · Licensing Engine

---

## Canonical workflow

```
Checkout
   ↓
Payment Verification          (PaymentPort.verifyWebhook)
   ↓
Subscription Creation         (BillingSubscriptionRecord)
   ↓
License Assignment            (createLicense / renewLicense)
   ↓
Customer Notification         (commercial email outbox)
   ↓
Portal Update                 (Billing · Licenses · Subscriptions · Invoices · Orders)
```

---

## Supported plans

| Plan | License type | Billing behaviour |
|------|--------------|-------------------|
| Trial | `trial` | `trialing` status · 14d catalog |
| Monthly | `monthly` | Active · next billing date set |
| Yearly | `yearly` | Active · next billing date set |
| Lifetime | `lifetime` | Active · no next billing |

---

## Event automation map

| Normalized event | Automation |
|------------------|------------|
| `payment.succeeded` / `subscription.created` | createLicense · invoice · payment · billing sub · purchase/invoice/receipt/license emails |
| `subscription.renewed` | renewLicense · renewal payment · receipt email |
| `payment.failed` / `subscription.past_due` | failed payment · mark past_due · payment_failure email |
| `subscription.cancelled` | cancel billing sub · cancellation_confirmation email |
| `refund.created` | refund payment · invoice → refunded |
| `dispute.opened` | disputed payment ledger (chargeback notice) |

Idempotency key: `providerEventId` in `processedWebhooks`.

---

## Scheduled / admin jobs

| Job | Function | Trigger |
|-----|----------|---------|
| Renewal reminders | `sendRenewalReminders()` | Admin Billing button · within 7 days of next billing |
| Expiry notices | `sendExpiryNotices()` | Admin Billing button · ended cancelled/expired/past_due |

---

## Dual subscription views

| Store | Meaning |
|-------|---------|
| Billing store subscriptions | Commercial / PSP ledger (provider, next billing) |
| Licensing store subscriptions | Entitlement / grace / device seats |

Linked by `licenseId` + customer email. Portal `/portal/subscriptions` shows both.

---

## Hard isolation rule

A payment failure, refund, chargeback, or expiry email **must never**:

- Stop or modify the Core Trading Engine
- Alter Strategy / Risk / Recovery / Order Execution / Magic Number logic
- Inject Website payment dependencies into the MQL5 Market Edition

Website Edition and MQL5 Market Edition share one certified Core — separate commercial models.

---

*End of SUBSCRIPTION_AUTOMATION.md*
