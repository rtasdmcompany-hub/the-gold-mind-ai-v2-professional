# BACKUP_AND_RECOVERY.md

**Phase 8 · Sprint 6**  
**Scope:** Commercial configuration, license lease metadata, user preferences, report library indexes  
**Out of scope:** Broker server-side history; Core strategy source rewrite

---

## 1. Backup types

### Automatic Backup
| Trigger | What |
|---------|------|
| Before config write | Snapshot previous profile set |
| Daily (idle) | Rotating commercial config pack |
| Before update apply | Full commercial state pack |
| After successful license change | Lease + device list metadata |

Retention: keep last N (e.g. 10) + one weekly pin.

### Manual Backup
- Diagnostics / Settings → “Backup now”  
- User chooses destination folder  
- Manifest + timestamp + build  

---

## 2. Configuration Restore

```
Select backup → Validate checksum → Preview diff → Confirm
  → Write restore → Re-validate → Restart commercial shell if required
  → Log System + Security channels
```

Never restore by silently patching live Core risk without Owner-facing confirmation — commercial prefs only by default.

---

## 3. Safe Recovery

| Condition | Action |
|-----------|--------|
| Corrupt config | Load last known good backup automatically if checksum fails |
| Corrupt lease | Fall to grace/revalidate; don’t crash loop |
| Partial write | Atomic replace (write temp → verify → swap) |

Safe Recovery aligns with Error Handling **Safe State**.

---

## 4. Rollback Strategy

| Layer | Rollback |
|-------|----------|
| Config | Previous automatic snapshot |
| Application update | Updater keeps N-1 package; “Rollback update” |
| Feature flags | Disable commercial feature flag without touching Core |

Rollback must be **one click** from Diagnostics when possible.

---

## 5. Disaster Recovery Workflow

```
1. Detect (Fatal/Critical integrity or unbootable shell)
2. Enter Safe State / blocking guidance
3. Export Diagnostics Pack
4. Restore last known good commercial backup
5. Revalidate license online
6. Confirm Health Summary = Healthy/Degraded (not Critical)
7. Resume normal commercial use
8. If still failing → Support with pack (no Core code changes by customer)
```

Open positions remain under **Core / broker** — DR here is commercial shell recoverability, not rewriting trade history.

---

## 6. What backups exclude

- Broker passwords  
- Full raw memory  
- Payment card data (never stored)  
- Unredacted license secrets in shareable packs  

---

*End of BACKUP_AND_RECOVERY.md*
