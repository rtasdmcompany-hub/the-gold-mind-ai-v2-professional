# PRODUCTION_ADMIN_LIST.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Template — replace placeholders with real production emails before go-live.**  
**Do not commit real personal emails to a public repository if policy forbids it.**

| Title | Role | Email | Status |
|-------|------|-------|--------|
| Owner | super_admin | owner@YOURDOMAIN | Waiting for Owner |
| Administrator | super_admin | admin@YOURDOMAIN | Waiting for Owner |
| Support | support_agent | support@YOURDOMAIN | Waiting for Owner |
| ReadOnly Admin | auditor | auditor@YOURDOMAIN | Waiting for Owner |

## Vercel env snippet (example)

```
PORTAL_SUPER_ADMIN_EMAILS=owner@YOURDOMAIN
PORTAL_ADMIN_EMAILS=admin@YOURDOMAIN
PORTAL_SUPPORT_EMAILS=support@YOURDOMAIN
PORTAL_AUDITOR_EMAILS=auditor@YOURDOMAIN
```

After setting values, each user must complete portal registration/login once.
