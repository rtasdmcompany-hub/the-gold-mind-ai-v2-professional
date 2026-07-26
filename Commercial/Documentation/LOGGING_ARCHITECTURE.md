# LOGGING_ARCHITECTURE.md

**Phase 8 · Sprint 6**  
**Goal:** Enterprise logging that supports supportability without leaking secrets  
**Rule:** Design only — Core logger APIs unchanged unless Owner-approved later

---

## 1. Log channels (separation)

| Channel | Contents |
|---------|----------|
| Trading | Order/lifecycle **observations** and journal-facing events (no secret payloads) |
| Recovery | Recovery state transitions (display/audit) |
| System | Startup, shutdown, init, timers, UI shell |
| Security | Tamper, auth failures, integrity fails |
| License | Validate, grace, activate, device bind (keys masked) |
| Updates | Installer / updater checks, checksum results |
| Diagnostics | Health snapshots, env checks |
| Performance | Timing, memory/CPU samples, slow ops |

---

## 2. Levels

| Level | Use |
|-------|-----|
| TRACE | Dev only; off in production default |
| DEBUG | Support builds / opt-in |
| INFO | Normal operations |
| WARN | Degraded |
| ERROR | Recoverable / critical failures |
| FATAL | Session-ending |

Default production: **INFO+** with Performance sampled.

---

## 3. Filtering

Users/Support can filter by:

- Channel  
- Level  
- Time range  
- Correlation / Trade ID (when present)  
- Text search  

UI: Diagnostics Center → Logs viewer (read-only).

---

## 4. Record shape

```
timestamp | level | channel | code | message | correlation_id | build
```

Optional structured JSON side-car for machine parse (commercial ops).

---

## 5. Retention & size

| Policy | Guidance |
|--------|----------|
| Rotation | Size + daily |
| Cap | Configurable max MB; drop oldest |
| Export | Include in diagnostics pack (redacted) |

---

## 6. Redaction rules (mandatory)

Never write plaintext:

- Full license keys / activation tokens  
- Portal passwords  
- Payment tokens  
- Broker passwords (should never be held)  

Mask account numbers in shared exports by default.

---

## 7. Performance hygiene

- Avoid per-tick TRACE in production  
- Batch Performance samples  
- Logging must not block trade path — async/buffered where architecture allows  
- Prefer OnTimer commercial logging over tick-hot paths  

---

## 8. Alignment note

Existing project logger conventions (e.g. `.Warning` API naming) remain; this document defines **commercial channel taxonomy** for production ops.

---

*End of LOGGING_ARCHITECTURE.md*
