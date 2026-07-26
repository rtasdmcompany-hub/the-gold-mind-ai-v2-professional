# LAUNCH_OPERATIONS.md

## Emergency contacts (fill before Stable)

| Role | Contact |
|------|---------|
| Owner | TBD |
| Engineering on-call | TBD |
| Support lead | TBD |
| PSP account owner | TBD |

## Maintenance

1. Announce window via Portal announcements + email template.  
2. Enable maintenance flag if available.  
3. Deploy.  
4. Smoke test.  
5. Clear maintenance.

## Incident response

1. Detect via observability alerts.  
2. Triage P0–P3.  
3. Mitigate commercial services only — **never** modify Core EA.  
4. Communicate via templates.  
5. Postmortem within 48h.

## Rollback

1. Redeploy previous GitHub/Vercel release.  
2. Restore `.data` from last DR drill if stores corrupted.  
3. Verify Core SHA unchanged.
