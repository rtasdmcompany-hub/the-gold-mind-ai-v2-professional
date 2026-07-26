# PRODUCT_EDITIONS.md

**Phase 8 · Sprint 1**  
**Product family:** THE GOLD MIND  
**Owner:** RTAS Group of Companies · RTAS Digital Marketing Company  
**Rule:** Commercial packaging only — Core Trading Engine frozen

---

## Edition A — THE GOLD MIND PROFESSIONAL

| Attribute | Definition |
|-----------|------------|
| **Commercial name** | THE GOLD MIND PROFESSIONAL |
| **Internal code** | `GM_EDITION_PROFESSIONAL` / Edition A |
| **Distribution** | Official Website (RTAS commercial channel) |
| **Target buyer** | Serious traders, desks, premium subscribers |
| **Install model** | Guided installer / sealed package + MT5 attach |
| **Licensing** | Website license · device activation · subscription |
| **Update model** | Automatic updates via Customer Portal / Deployment channel |
| **Support** | Enterprise Support |

### Enabled commercial capabilities (product scope)

- Full Dashboard (commercial IA — Trader / Investor / Admin modes planned)  
- AI Analytics (advisory / observe-only)  
- License Management  
- Cloud Account  
- Subscription lifecycle  
- Premium Reports  
- Customer Portal  
- Automatic Updates  
- Enterprise Support  

### Hard exclusions

- No commercial feature may open/close/modify trades  
- No remote trade commands  
- No changes to Risk / Strategy / Magic / Execution  

---

## Edition B — THE GOLD MIND MARKET

| Attribute | Definition |
|-----------|------------|
| **Commercial name** | THE GOLD MIND MARKET |
| **Internal code** | `GM_EDITION_MARKET` / Edition B |
| **Distribution** | MQL5 Market |
| **Target buyer** | MT5 Market customers needing simple, compliant install |
| **Install model** | Market one-click / MT5 Market install |
| **Licensing** | MQL5 Market license API (simple activation) |
| **Update model** | Market automatic updates |
| **Support** | Market comments + RTAS Market support policy |

### Market requirements (product constraints)

- No external dependency violating MQL5 Market rules  
- Simple activation  
- Market compliant packaging  
- Lightweight package  
- Broker compatible  
- Easy installation  

### Enabled (product scope)

- Frozen Core Trading Engine (same heart as Professional)  
- Compact commercial dashboard (essential status only)  
- Essential risk/recovery visibility (read-only UI)  
- Market license activation  
- Quick Start onboarding  

### Disabled / stripped for Market

- Website Customer Portal dependency  
- External cloud account requirement (unless Market-legal)  
- Heavy enterprise Command / Multi-Account federation UIs  
- Developer Phase closure telemetry surfaces  
- Optional research labs (or collapsed Advanced — product decision in Sprint 2+)  

---

## Shared across editions

| Shared | Note |
|--------|------|
| Core Trading Engine | Identical frozen Core |
| Manual trade isolation | Identical Magic 0 policy |
| Brand identity | Premium Black · Luxury Gold · RTAS / THE GOLD MIND |
| Safety doctrine | Commercial layers never affect live trading |

---

## Edition decision matrix (summary)

| Capability | Professional | Market |
|------------|:------------:|:------:|
| Full Dashboard | Yes | Compact |
| AI Analytics | Full advisory | Limited / optional |
| License Management | Website + portal | Market API |
| Cloud Account | Yes | No* |
| Subscription | Yes | Market billing |
| Premium Reports | Yes | Basic |
| Customer Portal | Yes | No |
| Automatic Updates | Portal/Deploy | Market |
| Enterprise Support | Yes | Standard Market |

\*Unless a future Market-legal offline-safe optional module is separately approved.

---

*End of PRODUCT_EDITIONS.md*
