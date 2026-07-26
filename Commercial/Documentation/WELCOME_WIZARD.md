# WELCOME_WIZARD.md

**Phase 8 · Sprint 2**  
**Product:** THE GOLD MIND PROFESSIONAL  
**Brand:** RTAS Group of Companies · THE GOLD MIND · Automated Trading Software  
**Theme:** Premium Black · Luxury Gold · Modern Enterprise  
**Rule:** Wizard never modifies Trading Engine / Risk / Strategy / Execution / Recovery

---

## Purpose

Convert first launch anxiety into confidence in ≤10–15 minutes.

Experts may use **Skip to Advanced** after Page 1 (except mandatory risk acknowledgment where legally required).

---

## Page 1 — Welcome

**Title:** Welcome to THE GOLD MIND  

**Content:**
- Product name: THE GOLD MIND  
- Owner: RTAS Group of Companies  
- Division cue: RTAS Digital Marketing Company  
- Version / Build (from product identity)  
- Edition: PROFESSIONAL (or MARKET compact variant)  
- One sentence: *Professional automated gold trading software with a frozen Core execution engine.*  

**CTA:** Continue · Learn more (optional)  

**Visual:** Official splash / logo assets only (no redesign)

---

## Page 2 — System Check

Automated checks with clear Pass / Warn / Fail:

| Check | Pass | Fail guidance |
|-------|------|---------------|
| MT5 installed | Terminal found | Install MetaTrader 5 |
| Windows version | Supported OS | Show minimum OS |
| Disk space | ≥ free threshold | Free space / change path |
| Permissions | Can write Config/Logs | Run as needed / fix ACL |
| Internet connection | Online (for license) | Offline grace policy note |

**CTA:** Recheck · Continue (enabled only if no hard Fail)

---

## Page 3 — License Activation

| Field / state | Spec |
|---------------|------|
| License key | Paste / type |
| Sign in | Portal account (Professional) |
| Activation status | Pending / Active / Failed / Device limit |
| Device registration | Show device label; register on success |

**CTA:** Activate · Having trouble? (Support)  

**Never:** Activation success must not enable trade APIs in the wizard.

---

## Page 4 — Broker / Terminal Detection

| Element | Spec |
|---------|------|
| Auto-detect | Scan installed MT5 terminals |
| List | Path · broker company (if readable) · last used |
| Selection | User picks primary terminal |
| Multi-terminal | Professional may remember preferred terminal; no remote trading |

**CTA:** Refresh list · Continue  

See `BROKER_DETECTION.md`.

---

## Page 5 — Trading Preferences (commercial catalogs only)

| Preference | Notes |
|------------|-------|
| Risk Level | Conservative / Balanced / Aggressive — **profile catalog labels** for later config import; does **not** write live Core risk at wizard time unless separately approved non-trading preference store |
| Notifications | On/Off channels (email/app — Professional) |
| Language | EN default + future locales |
| Theme | Premium Black · Luxury Gold (default) |
| Default Workspace | Trader (default) / Investor / Admin |

**Hard rule:** Preferences save to commercial configuration store only.  
They must not call Risk Management or alter execution parameters during onboarding.

---

## Page 6 — Tutorial

Short guided cards (skipable for experts):

1. **Dashboard** — status, health, next action  
2. **Charts** — MT5 chart is where the EA attaches  
3. **Trading Controls** — Core owns trading; UI does not “press buy”  
4. **Reports** — performance / premium reports  
5. **Logs** — where to find answers before Support  
6. **Support** — FAQ · Enterprise Support entry  

---

## Page 7 — Finish

| Element | Spec |
|---------|------|
| Headline | System Ready |
| Checklist | License · MT5 · Terminal · Workspace |
| Primary CTA | Launch Dashboard |
| Secondary | Open Quick Start · Contact Support |
| Footer | Manual trades remain isolated · Core is sole execution authority |

---

## Wizard UX quality bar

| Bar | Requirement |
|-----|-------------|
| Beginner | One idea per page; plain language |
| Professional | No cartoon clutter; gold/black brand discipline |
| Commercial | Progress indicator 1–7; resume later |
| Enterprise | Accessible errors; support deep-links with correlation ID |

---

## Market edition variant

Pages collapsed to: Welcome → License/Market activate → Tips → Finish.  
No external portal-required steps.

---

*End of WELCOME_WIZARD.md*
