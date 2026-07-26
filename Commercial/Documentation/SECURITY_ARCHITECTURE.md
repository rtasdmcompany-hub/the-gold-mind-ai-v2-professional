# SECURITY_ARCHITECTURE.md

**Phase 8 · Sprint 6**  
**Scope:** Production security for THE GOLD MIND PROFESSIONAL commercial deployment  
**Extends:** Sprint 3 `SECURITY_MODEL.md` (licensing/portal)  
**Rule:** Recommendations only — Core Trading / Strategy / Order / Risk / Recovery / AI Decision Logic remain frozen

---

## 1. Guiding principle

Reliability and security beat new features.  
THE GOLD MIND must behave like enterprise financial software: **Predictable · Stable · Secure · Recoverable**.

---

## 2. Domain review & recommendations

### 2.1 License Protection
| Finding | Recommendation |
|---------|----------------|
| Entitlement is a commercial control plane | Keep server-signed leases; short TTL; seat binding (Sprint 3) |
| Local key exposure | Mask in UI; store hashed/encrypted lease; never log full keys |
| Offline abuse window | Bound offline grace; force revalidate |

### 2.2 Configuration Protection
| Finding | Recommendation |
|---------|----------------|
| Profiles can be edited / corrupted | Sign or checksum critical commercial profiles; validate on load |
| Accidental overwrite | Versioned config + backup before write (see Backup doc) |
| Core risk inputs | Commercial shell must not silently rewrite live Core risk files |

### 2.3 Secure Storage
| Finding | Recommendation |
|---------|----------------|
| Secrets on disk | Prefer OS credential store / DPAPI-style protection where available |
| App data paths | Restricted ACLs on license, tokens, diagnostics packs |
| Temp files | Wipe export temps; no secrets in `%TEMP%` leftovers |

### 2.4 Credential Handling
| Finding | Recommendation |
|---------|----------------|
| Broker passwords | **Never** collect or store — MT5 owns broker auth |
| Portal passwords | Hash at rest (server); TLS in transit; MFA later |
| API keys (cloud) | Rotate; scoped; never embed in EA source |

### 2.5 API Security
| Finding | Recommendation |
|---------|----------------|
| Portal / license APIs | AuthN + AuthZ; rate limits; idempotent webhooks |
| Client calls | Mutual trust via tokens; certificate pinning where feasible |
| Error leakage | Generic client errors; detailed only in secured logs |

### 2.6 Communication Security
| Finding | Recommendation |
|---------|----------------|
| All commercial network | TLS 1.2+ |
| Webhooks | Signature verify (Paddle/PayPal) |
| Downgrade attacks | Reject cleartext entitlement endpoints |

### 2.7 File Integrity
| Finding | Recommendation |
|---------|----------------|
| Installer / updates | Checksums + optional code signing |
| Critical commercial files | Manifest hash verify at startup (shell) |
| Customer exports | Optional integrity footer on PDF packs |

### 2.8 Tamper Detection
| Finding | Recommendation |
|---------|----------------|
| Lease / config surgery | Integrity MAC fail → safe limited mode + Diagnostics |
| Debugger / hook suspicion | Log Security event; do not change Core trade math |
| Response | Graceful degrade of commercial features — never revenge-trade |

### 2.9 Session Security
| Finding | Recommendation |
|---------|----------------|
| Portal sessions | HTTP-only cookies; idle + absolute TTL; logout-all |
| Local shell session | Re-auth for sensitive actions (deactivate device, export diagnostics with secrets redacted) |

### 2.10 Local Data Protection
| Finding | Recommendation |
|---------|----------------|
| Journals / reports | Account masking option on share |
| Logs | Redact keys, emails partially, tokens |
| Crash dumps | Strip secrets before Support upload |

---

## 3. Separation from Core

| Security may | Security must never |
|--------------|---------------------|
| Gate commercial features | Alter order placement logic |
| Invalidate license lease | Patch Recovery / Risk algorithms |
| Quarantine corrupted config | Bypass Magic 0 isolation |

---

## 4. Priority backlog (reliability-first)

1. License lease integrity + redaction in logs  
2. Config checksum + auto-backup before write  
3. TLS + webhook verify on all commercial endpoints  
4. Diagnostics pack scrubber  
5. Code-signed installer / updates  

---

*End of SECURITY_ARCHITECTURE.md*
