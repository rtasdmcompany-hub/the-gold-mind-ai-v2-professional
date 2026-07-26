# Phase 6 — Administrator Guide

## Startup checklist

1. Attach EA on XAUUSD chart with correct Magic  
2. Confirm Phase 6 freeze banners in Experts log  
3. Confirm `Phase 6 Closed | PASS` (or review FAIL items)  
4. Review `GM_PHASE6_*` files in common files folder  
5. Verify Deployment Center / certification overlay values  

## Operations

- Monitor Cloud / Remote / Notify / Infra / Identity / Backup / Audit / API / Deploy health via dashboard widgets  
- Never use infrastructure surfaces to force trade changes  
- Schedule updates only when no GM-managed positions are open  

## Escalation

If closure reports FAIL: inspect `GM_PHASE6_Infrastructure_Module_Audit.txt` and fix readiness of failing modules before Phase 7.
