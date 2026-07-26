# INSTALLATION_FLOW.md

**Phase 8 · Sprint 2**  
**Edition focus:** THE GOLD MIND PROFESSIONAL (Website)  
**Market edition:** Simplified path (see notes)  
**Rule:** Commercial UX only — Core Trading Engine frozen

---

## End-to-end customer journey

```
Purchase
   ↓
Receive download (portal / email)
   ↓
Run installer
   ↓
Installation verification
   ↓
License activation
   ↓
Platform detection (MT5)
   ↓
Broker / terminal verification
   ↓
Workspace initialization
   ↓
Welcome Wizard
   ↓
Commercial Dashboard
   ↓
Ready for first trade (Core remains sole executor)
```

---

## Stage specifications

### 1. Purchase
| Item | Spec |
|------|------|
| Channel | Official Website / Customer Portal |
| Output | Order confirmation + secure download link + license entitlement |
| Tone | Premium Black · Luxury Gold · calm confidence |

### 2. Receive download
| Item | Spec |
|------|------|
| Package | Sealed Professional installer (signed when available) |
| Verify | Checksum / authenticity note on download page |
| Fallback | Re-download from Customer Portal |

### 3. Run installer
| Item | Spec |
|------|------|
| UI | Branded splash · RTAS Group of Companies · THE GOLD MIND |
| Modes | Express (recommended) · Custom (advanced) |
| Elevation | Request admin only if required for Program Files / services |
| Cancel | Safe exit; no partial Core corruption |

### 4. Installation verification
| Check | Pass criteria |
|-------|---------------|
| Files present | Product binaries + commercial shell assets |
| Folders created | Logs · Backup · Configuration · Data |
| Shortcuts | Desktop + Start Menu (user choice) |
| Write access | Config/Log folders writable |
| Integrity | Manifest hash OK |

### 5. License activation
See `LICENSE_ACTIVATION_FLOW.md`.

### 6. Platform detection (MT5)
| Item | Spec |
|------|------|
| Detect | Installed MetaTrader 5 terminals on device |
| Empty state | Guide to install MT5 if missing |
| Continue | Block “Launch Dashboard” until MT5 path known or user acknowledges external install |

### 7. Broker / terminal verification
See `BROKER_DETECTION.md`.

### 8. Workspace initialization
| Item | Spec |
|------|------|
| Create | Default commercial workspace profile |
| Theme | Premium Black · Luxury Gold |
| Language | User selection (default EN) |
| Folders | Bind to Log / Backup / Config paths |
| **Never** | Mutate live risk, magic, or strategy constants |

### 9. Welcome Wizard
See `WELCOME_WIZARD.md`.

### 10. Dashboard → Ready
| Item | Spec |
|------|------|
| Land | Trader mode commercial dashboard |
| Status | “System Ready — attach EA on chart to arm Core” |
| First trade | Educational: Core executes only after MT5 attach + Algo Trading enabled |
| Support | One-click Help / FAQ |

---

## Professional installer features

| Feature | Behavior |
|---------|----------|
| Desktop shortcut | Optional, default ON |
| Start Menu shortcut | Default ON |
| Auto Update Service | Professional only — checks portal; **never** changes Core trading logic |
| Log folder | `%AppData%/THE_GOLD_MIND/Logs` (or product standard path) |
| Backup folder | `%AppData%/THE_GOLD_MIND/Backup` |
| Configuration folder | `%AppData%/THE_GOLD_MIND/Config` |
| Safe uninstall | Removes shell/shortcuts; preserves user backups unless opted out; does not touch MT5 history |

---

## Market edition (B) — simplified install flow

```
Market purchase → Market install → Simple activation → Short tips → Attach EA → Ready
```

No external installer dependency that violates MQL5 rules.  
No mandatory Customer Portal for boot.

---

## Failure & recovery

| Failure | Customer action |
|---------|-----------------|
| Install verify fail | Repair mode / re-download |
| No MT5 | Open MT5 download guide; resume wizard later |
| License fail | Retry / contact Enterprise Support |
| No terminal selected | Cannot finish; show why |

---

*End of INSTALLATION_FLOW.md*
