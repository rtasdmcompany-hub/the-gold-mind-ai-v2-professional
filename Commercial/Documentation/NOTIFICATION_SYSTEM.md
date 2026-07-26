# NOTIFICATION_SYSTEM.md

**Phase 8 · Sprint 5**  
**Goal:** Professional, calm, actionable alerts — confidence without alarm fatigue  
**Rule:** Notifications inform; they do not execute trades or change risk

---

## 1. Categories

| Category | Intent | Example |
|----------|--------|---------|
| Trading | Trade lifecycle visibility | Position opened / closed (summary) |
| Recovery | Recovery state changes | Recovery started / completed / idle (display) |
| Risk | Risk posture warnings | Margin warn threshold approached |
| License | Entitlement | Grace started · Expired · Renewed |
| Updates | Product / shell | New version available |
| Warnings | Soft problems | High spread · session closed |
| Errors | Hard failures | Broker disconnect · validation failed |
| Information | Neutral | Report ready · export complete |
| Success | Confirmations | License activated · export saved |

---

## 2. Severity model

| Severity | UI | Desktop toast | Persist in tray |
|----------|-----|---------------|-----------------|
| Success | Green badge | Optional brief | No |
| Information | Blue | Optional | Short |
| Warning | Amber | Yes | Until dismiss / resolve |
| Error | Red | Yes | Until dismiss / resolve |
| Critical | Red + banner | Yes | Banner until action |

---

## 3. Channels

| Channel | Spec |
|---------|------|
| In-app toast | Corner stack; max 3 visible |
| Notification center (bell) | History, filter by category |
| Banner | License grace, disconnect |
| Desktop OS notification | Opt-in; see §5 |
| Email (portal) | License / billing / security — not every trade tick |

---

## 4. Content template

```
[Category] Title (≤60 chars)
One-line body (≤120 chars)
Optional: View · Dismiss · Open Journal / License
Timestamp · Demo/Live tag
```

Tone: precise, premium, no hype. Never “guaranteed profit.”

---

## 5. Desktop notification planning

| Topic | Plan |
|-------|------|
| Opt-in | Default off for Trading ticks; on for Errors / License |
| Throttle | Collapse bursts (e.g. many closes → one summary) |
| Quiet hours | User preference (future) |
| Payload | Title + body only — no account passwords |
| Platform | Windows toast via commercial shell / helper when available; MT5-only builds may limit to in-terminal |

Desktop notifications are **commercial shell capability** — not a Core Trading change.

---

## 6. Anti-spam rules

- No per-tick spam  
- Aggregate: “3 positions closed · net +X”  
- User prefs: mute category  
- Critical never fully muteable without explicit override  

---

## 7. Mapping to confidence

| User worry | Notification helps |
|------------|--------------------|
| “Did something fail?” | Error / Broker disconnect |
| “Is my license OK?” | License category |
| “Is recovery running?” | Recovery status change |
| “Was I flooded with noise?” | Throttle + prefs |

---

*End of NOTIFICATION_SYSTEM.md*
