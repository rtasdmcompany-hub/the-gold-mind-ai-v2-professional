# SECRET_MANAGEMENT.md

**Phase:** 10 · Sprint 6  
**UI:** `/portal/admin/secret-management`  

---

## Verified

| Area | Guidance |
|------|----------|
| Environment Variables | `NEXTAUTH_SECRET` required; store secrets recommended |
| API Keys | Upstash optional until multi-instance |
| OAuth Secrets | `GOOGLE_CLIENT_*` for production auth |
| Webhook Secrets | `SANDBOX_WEBHOOK_SECRET` non-default in production; PSP secrets env-gated |
| Encryption Keys | `LICENSE_STORE_SECRET`, `BILLING_STORE_SECRET`, `AUDIT_STORE_SECRET`, `SECURITY_STORE_SECRET` |
| Rotation | Dual-read `*_PREVIOUS` · ≤48h overlap · re-encrypt · drop previous |

## Rules

- Never commit `.env.local`
- Never expose secrets via `NEXT_PUBLIC_*`
- Production rejects known insecure defaults (sandbox webhook)

## Template

See `Commercial/CustomerPortal/web/.env.local.example`
