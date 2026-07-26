# PRODUCTION_HARDENING.md

**Phase 8 · Sprint 6**  
**Includes:** Application Stability Report (Task 2) · Production Readiness Review (Task 8)  
**Rule:** Prefer reliability over features · Core Trading Engine frozen

---

## PART A — Application Stability Report

### A.1 Startup Sequence
| Expectation | Hardening |
|-------------|-----------|
| Deterministic init order | Shell → license lease read → config validate → UI → deferred network |
| Failure mid-init | Abort to Fatal/Critical UX with Diagnostics; no half-bound commercial state |
| Slow license network | Use offline lease + async validate |

### A.2 Shutdown Sequence
| Expectation | Hardening |
|-------------|-----------|
| Flush logs | Bounded wait; never hang forever |
| Persist UI prefs | Atomic write |
| Cancel background jobs | Cooperative cancel |

### A.3 Unexpected MT5 Restart
| Expectation | Hardening |
|-------------|-----------|
| OnInit again | Rehydrate from lease + last config; no duplicate commercial side effects |
| Idempotent timers | Safe if Process runs twice |

### A.4 Internet Loss
| Expectation | Hardening |
|-------------|-----------|
| Entitlement | Offline grace per Security Model |
| Reports/cloud | Degrade with clear banner |
| Trading | Core policy unchanged — do not “help” by closing trades |

### A.5 Broker Disconnect
| Expectation | Hardening |
|-------------|-----------|
| Detect | Health + Warning/Critical notifications |
| UI | Show disconnected; queue non-critical commercial sync |
| Reconnect | Auto clear banner; INFO log |

### A.6 Chart Reload
| Expectation | Hardening |
|-------------|-----------|
| Objects rebuilt | Dashboard recreate idempotently |
| No duplicate timers | Guard single commercial timer owner |

### A.7 Platform Restart (OS / terminal)
| Expectation | Hardening |
|-------------|-----------|
| Same as cold start | Rely on backups + lease |
| Crash leftover locks | Stale lock timeout on config files |

### A.8 Configuration Recovery
| Expectation | Hardening |
|-------------|-----------|
| Checksum fail | Auto last-known-good (Backup doc) |
| User cancel | Remain on previous good |

### A.9 Safe State Restoration
| Expectation | Hardening |
|-------------|-----------|
| After Critical | Restore UI to Safe State until Health Summary improves |
| Exit Safe State | Explicit: all critical findings cleared or acknowledged per policy |

### A.10 Stability verdict (architecture)

| Area | Design readiness |
|------|------------------|
| Lifecycle coverage | Complete on paper |
| Safe degrade paths | Specified |
| Core isolation under faults | Affirmed |
| Implementation | Deferred — required before public launch |

---

## PART B — Production Readiness Review

| Area | Review | Recommendation |
|------|--------|----------------|
| Installer Reliability | Critical path | Signed package · checksum · repair mode · failed-install rollback |
| Update Reliability | Critical path | Staged update · N-1 rollback · post-update Health check |
| Crash Recovery | Required | Diagnostics on next start · config backup · no silent corruption |
| Diagnostic Information | Required | Diagnostics Center + redacted packs |
| Support Readiness | Required | Stable error codes · KB mapping · pack intake |
| Maintainability | Required | Channelized logs · frozen Core boundary docs |
| Scalability | Commercial ops | Payment/license services scale independently of EA |
| Long-Term Stability | Required | Prefer timer-bound commercial work · leak/perf sampling · reliability over features |

---

## PART C — Hardening checklist (pre-release)

- [ ] License lease integrity + redaction  
- [ ] Config atomic write + auto-backup  
- [ ] Startup/shutdown/reconnect matrix tested  
- [ ] Error severity taxonomy implemented in shell  
- [ ] Log channels + rotation  
- [ ] Diagnostics Center + pack  
- [ ] Update rollback verified  
- [ ] Long-session soak (multi-day)  

---

## PART D — Non-negotiables

1. Reliability > features  
2. Predictable · Stable · Secure · Recoverable  
3. Fault handlers never become trade executors  
4. Core Trading Engine remains frozen  

---

*End of PRODUCTION_HARDENING.md*
