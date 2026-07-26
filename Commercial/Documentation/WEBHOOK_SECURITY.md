# WEBHOOK_SECURITY.md

**Phase:** 9 · Sprint 4  
**Endpoint:** `POST /api/billing/webhooks/[provider]`  
**Providers:** `paddle` · `paypal` · `sandbox` (Stripe future)  
**Edition:** Website only

---

## Guarantees (every webhook)

| Property | Implementation |
|----------|----------------|
| **Authenticated** | `PaymentPort.verifyWebhook` — HMAC / provider signature |
| **Logged** | Console + `webhookAudits[]` in encrypted billing store |
| **Idempotent** | `providerEventId` dedupe via `processedWebhooks` |
| **Retry-safe** | Duplicate → `{ ok: true, duplicate: true }` · no second license |

Unauthorized → **401** · Unknown provider → **404** · Process error → **500** (safe to retry).

Plaintext license keys are **never** returned on webhook HTTP responses.

---

## Public route (no portal session)

Middleware treats `/api/billing/webhooks/*` as **public**.  
PSPs cannot present Customer Portal cookies; authentication is **signature-only**.

```
middleware.ts
  isPublic = /login | /api/auth* | /api/billing/webhooks*
```

---

## Signature headers

| Provider | Header(s) | Secret env |
|----------|-----------|------------|
| Sandbox | `x-tgm-sandbox-signature` | `SANDBOX_WEBHOOK_SECRET` |
| Paddle | `paddle-signature` / `x-paddle-signature` | `PADDLE_WEBHOOK_SECRET` |
| PayPal | `paypal-transmission-sig` / `x-paypal-signature` | `PAYPAL_WEBHOOK_ID` / `PAYPAL_WEBHOOK_SECRET` |

Comparison uses timing-safe equality (`safeEqual`).

Production without configured secrets: verification fails closed (returns null → 401).  
Non-production may fall back to sandbox signature shape for local integration tests.

---

## Audit log fields

`WebhookAuditEntry`:

- `provider` · `authenticated` · `httpStatus`
- `eventType` · `providerEventId` · `duplicate`
- `detail` · `at`

Visible on Admin Billing → **Webhook Audit (security log)**.

---

## Handled commercial signals

Successful payment · Failed payment · Refund · Subscription renewal · Subscription cancellation · Chargeback / dispute (`dispute.opened`).

---

## Threat notes

| Threat | Mitigation |
|--------|------------|
| Forged webhook | Signature verify before process |
| Replay | Idempotent event id store |
| License leak via API | Response omits plaintext key |
| Session bypass abuse | Route is public but useless without valid HMAC |
| Trading impact | Processor never imports Trading / Risk / Recovery |

---

*End of WEBHOOK_SECURITY.md*
