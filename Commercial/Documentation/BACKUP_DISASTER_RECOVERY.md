# BACKUP_DISASTER_RECOVERY.md

**Phase:** 10 · Sprint 6  
**UI:** `/portal/admin/disaster-recovery`  
**Disaster Recovery Score:** **100** (drill suite)

---

## Validated

| Item | Target / Result |
|------|-----------------|
| Database Backup | Drill copies policy targets under `.data/security/backups/<id>` |
| Configuration Backup | `.env.local.example` versioned; live secrets never committed |
| Recovery Procedures | Stop → restore `.data` targets → validate secrets → start |
| Restore Testing | Manifest verification (non-destructive) |
| Rollback | Expand-contract migrations · backup required · Core frozen |
| RTO | ≤ 4 hours (Controlled Launch commercial portal) |
| RPO | ≤ 24 hours (daily policy default) |

## Hard rule

DR procedures restore **commercial** stores only. Core Trading Engine binaries on customer MT5 terminals are never part of portal backup/restore.
