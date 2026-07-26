# Phase 6 — Infrastructure Architecture Guide

**Edition:** Professional Enterprise  
**Build:** 21050 · Phase 6 FROZEN

## Layers

1. **Cloud Core** — device identity, license session architecture, sync queue, offline-safe mode  
2. **Remote Monitor** — health, telemetry, remote management (observe-only)  
3. **Notifications** — alert rules, queue, mobile companion API catalog  
4. **Infrastructure** — VPS, multi-terminal, enterprise control center  
5. **Identity** — license, auth, device activation (never gates live trading via grace/offline)  
6. **Backup** — backup engine, DR, business continuity  
7. **Audit** — forensic log, compliance, integrity  
8. **API Gateway** — auth, rate limits, integration hub, developer catalog (read-only)  
9. **Deployment** — release, auto-update, rollback (deferred during active GM trades)  
10. **Closure** — Phase 6 certification package (`Include/Phase6/`)

## Non-authority rule

Infrastructure may authenticate, synchronize, monitor, notify, backup, recover, audit, report, deploy, and integrate.

It must never open/close trades or modify orders, pending orders, SL, TP, or risk.
