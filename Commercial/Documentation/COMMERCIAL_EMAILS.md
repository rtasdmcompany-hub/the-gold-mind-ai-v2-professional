# COMMERCIAL_EMAILS.md

**Phase:** 9 · Sprint 4  
**Module:** `Commercial/CustomerPortal/web/src/server/billing/email.ts`  
**Edition:** Website transactional mail · not EA/Cloud Notifications

---

## Templates

| Template ID | Subject theme | Trigger |
|-------------|---------------|---------|
| `purchase_confirmation` | Purchase confirmed | Successful payment / subscription create |
| `invoice` | Your invoice | After purchase (links plan + license id) |
| `receipt` | Payment receipt | Payment or renewal |
| `license_delivery` | Your license key | After `createLicense` (one-time key in body) |
| `renewal_reminder` | Renewal reminder | `sendRenewalReminders()` (≤7 days) |
| `payment_failure` | Payment failed | Failed / past_due webhook |
| `subscription_expiry` | Subscription expired | `sendExpiryNotices()` |
| `cancellation_confirmation` | Subscription cancelled | Cancel webhook |

---

## Delivery model (Sprint 4)

1. `queueCommercialEmail()` writes to encrypted billing outbox (`emails[]`).
2. Status marked `sent` for MVP (outbox is the system of record).
3. Non-production (or `BILLING_EMAIL_LOG=true`) also `console.info`s the send.

**Future:** swap transport to SMTP / Amazon SES / Resend behind the same `queueCommercialEmail` API — template IDs stay stable.

---

## Customer visibility

Billing Center shows the customer’s recent outbox rows (template · subject · status · time).

Admin can queue renewal reminders and expiry notices from `/portal/admin/billing`.

---

## Content rules

- Brand: THE GOLD MIND PROFESSIONAL (Website Edition).
- Payment failure copy explicitly states Core Trading Engine is unaffected.
- License delivery is the only template that may include plaintext key material.
- Never email Market-edition activation codes through this Website pipeline.

---

## Separation from MT5 notifications

`Include/Cloud/Notifications/` (EA stack) is **not** this commercial email system.  
Do not route purchase / invoice / license delivery through the Expert Advisor.

---

*End of COMMERCIAL_EMAILS.md*
