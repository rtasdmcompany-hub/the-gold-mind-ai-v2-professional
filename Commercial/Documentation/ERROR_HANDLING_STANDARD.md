# ERROR_HANDLING_STANDARD.md

**Phase 8 · Sprint 6**  
**Goal:** Predictable, user-clear, support-ready error management  
**Rule:** Framework design only — does not rewrite Core trading exception paths in this sprint

---

## 1. Severity classification

| Level | Name | Meaning |
|------:|------|---------|
| 0 | Information | Expected lifecycle note |
| 1 | Warning | Degraded but operable |
| 2 | Recoverable Error | Failed operation; safe retry / alternate path possible |
| 3 | Critical Error | Major subsystem impaired; trading confidence reduced |
| 4 | Fatal Error | Cannot continue commercial session safely; controlled stop |

---

## 2. Per-category contract

### Information
| Aspect | Spec |
|--------|------|
| Detection | Explicit info events (export done, license OK) |
| Logging | `INFO` · System / domain channel |
| User Message | Toast or silent tray — optional |
| Automatic Recovery | N/A |
| Escalation | None |

### Warning
| Aspect | Spec |
|--------|------|
| Detection | Thresholds (spread, stale data, grace license) |
| Logging | `WARN` · include context ids |
| User Message | Amber badge / toast; actionable if possible |
| Automatic Recovery | Soft mitigate when safe (refresh, reconnect attempt) |
| Escalation | Repeat N times → elevate to Recoverable |

### Recoverable Error
| Aspect | Spec |
|--------|------|
| Detection | Failed validate, transient network, file lock |
| Logging | `ERROR` · error code · retry count |
| User Message | Clear cause + “Retry” / “Open Diagnostics” |
| Automatic Recovery | Bounded retries with backoff; then surface |
| Escalation | Exhausted retries → Critical |

### Critical Error
| Aspect | Spec |
|--------|------|
| Detection | Broker lost, config corrupt, license revoked mid-session |
| Logging | `ERROR`/`CRITICAL` · stack/context sanitized |
| User Message | Persistent banner; no panic language |
| Automatic Recovery | Enter **Safe State** (display/observe limits); do not invent trades |
| Escalation | Offer Support pack; block risky commercial actions |

### Fatal Error
| Aspect | Spec |
|--------|------|
| Detection | Unrecoverable init failure, integrity cascade |
| Logging | `FATAL` · last-breath diagnostics flush |
| User Message | Blocking dialog: cannot start safely + Support path |
| Automatic Recovery | Controlled shutdown of commercial shell; leave Core policy untouched |
| Escalation | Mandatory diagnostics prompt |

---

## 3. Standard error object (logical)

```
code          // stable machine code e.g. LIC_VALIDATE_TIMEOUT
severity      // 0–4
category      // Trading|Recovery|System|Security|License|...
message_user  // calm, short
message_log   // detailed, redacted
correlation_id
retryable     // bool
safe_state    // bool — enter safe mode?
```

---

## 4. User message rules

| Do | Don’t |
|----|-------|
| Say what failed + next step | Dump HRESULT walls |
| “Broker disconnected — waiting to reconnect” | “Fatal exception 0x…” as only UX |
| Link Diagnostics / Support | Blame the user |
| Preserve Demo/Live context | Hide severity |

---

## 5. Safe State (definition)

When Critical/Fatal commercial conditions occur:

- Preserve last known good UI status labels  
- Disable entitlement-gated commercial actions that require integrity  
- **Never** place, modify, or close trades as an “error handler”  
- Core remains sole execution authority under its own frozen rules  

---

## 6. Mapping to notifications

Align severities with Sprint 5 `NOTIFICATION_SYSTEM.md` (Info → Success/Information, Warn → Warning, Error+ → Errors).

---

*End of ERROR_HANDLING_STANDARD.md*
