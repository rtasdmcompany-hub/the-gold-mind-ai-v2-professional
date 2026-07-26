# API_REFERENCE.md

Base: `/api/v1`

| Method | Path | Scope |
|--------|------|-------|
| GET | `/api/v1/profile` | profile:read |
| GET | `/api/v1/licenses` | licenses:read |
| GET | `/api/v1/subscriptions` | subscriptions:read |
| GET | `/api/v1/invoices` | invoices:read |
| GET | `/api/v1/downloads` | downloads:read |
| GET | `/api/v1/notifications` | notifications:read |
| GET | `/api/v1/support/tickets` | support:read |
| GET | `/api/v1/partners` | partners:read |
| GET | `/api/v1/organizations` | organizations:read |
| GET | `/api/v1/webhooks` | webhooks:manage |
| POST | `/api/v1/webhooks` | webhooks:manage |
| POST | `/api/v1/oauth/token` | — |
| GET | `/api/v1/health` | public |

Scopes: profile:read, licenses:read, licenses:write, subscriptions:read, invoices:read, downloads:read, notifications:read, support:read, support:write, partners:read, organizations:read, webhooks:manage
