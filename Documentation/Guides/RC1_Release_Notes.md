# RC-1 Release Notes

**THE GOLD MIND AI PROFESSIONAL v2.0.0 (build 9009) — Release Candidate 1**

## Highlights

- Production Hardening layer (`Include/Production/`)
- Fail-safe gates for disconnect, trading disabled, low margin/memory
- Security guard against duplicates, invalid tickets, race conditions
- Live execution validation (SL/TP/BE/Partial/Session)
- Enterprise structured logging fields
- Runtime modes: Production / Debug / Development
- Tick-path IO optimization without changing trading behavior

## Unchanged

- Gold Mind H4 level calculation  
- Risk: 3% lots, 30-pip SL, ATR(14) TP  
- BE +50 / Partial 80/20 / Trail 30  
- Magic ownership rules  

## Install

1. Compile `Experts/TheGoldMindAI_Professional.mq5`  
2. Attach to XAU chart (H4 strategy timeframe enforced internally)  
3. Set unique Magic Number  
4. Prefer **Production Mode** + **Performance Mode** for live  

## Not in RC-1

AI Intelligence · Hedge · Dashboard · Cloud · Mobile (future sprints)
