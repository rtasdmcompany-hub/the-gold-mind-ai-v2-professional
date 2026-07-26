# Production Checklist — Phase 1 Core

## Pre-Deploy

- [ ] Compile EA in MetaEditor with project `/include` root → **0 errors / 0 warnings**  
- [ ] Confirm build **10010** in logs (`GmVersionBanner`)  
- [ ] Set Magic Number (default **112233**) — do not collide with other EAs  
- [ ] Symbol = intended Gold symbol (broker-specific spelling)  
- [ ] Runtime Mode = Production  
- [ ] Fail Safe ON  
- [ ] Security Guard ON  
- [ ] Run Validation On Startup = ON (first attach)  
- [ ] Confirm Architecture Freeze banner in Experts log  

## First Attach (Demo recommended)

- [ ] EA initializes to RUNNING  
- [ ] Review `GM_Phase1_Closure_Report.txt` → PHASE1_DECISION=PASS  
- [ ] Confirm 6 pending levels behavior on new H4 (per strategy)  
- [ ] Confirm no interaction with manual trades  
- [ ] Restart EA → recovery of registry / levels / trade mgmt flags  

## Soak Test

- [ ] Multi-session H4 rollover  
- [ ] Internet disconnect / reconnect (FailSafe)  
- [ ] Terminal restart with open GM positions  
- [ ] Verify BE / Partial / Trail only on own Magic  

## Go-Live Gate

- [ ] Stakeholder signed Phase 1 Closure  
- [ ] Demo soak accepted  
- [ ] Risk limits understood (3% / 30 pip SL)  
- [ ] Monitoring / log retention process defined  

## Do Not

- [ ] Change level fractions or risk constants  
- [ ] Attach with Magic 0  
- [ ] Enable unapproved Phase 2 AI decision hooks on live capital
