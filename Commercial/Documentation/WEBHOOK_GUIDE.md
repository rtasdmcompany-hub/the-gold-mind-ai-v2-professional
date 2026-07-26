# WEBHOOK_GUIDE.md

## Events

- `license.activated`
- `license.expired`
- `subscription.renewed`
- `payment.received`
- `refund.processed`
- `support.ticket.updated`
- `customer.created`
- `partner.registered`

## Signing

HMAC-SHA256 over `{timestamp}.{body}`; header X-TGM-Signature: t=...,v1=...

## Retry

Max attempts: 5  
Backoff (sec): 60, 300, 900, 3600, 14400

Suite deliveries: **8**
