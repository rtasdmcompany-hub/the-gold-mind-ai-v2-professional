# Phase 6 — Developer Guide

## Extending infrastructure (Phase 7+)

1. Create a new module folder — do not edit frozen `Include/Cloud/<Sprint1-9>/` cores  
2. Expose a facade with `Init` / `Process` / `Shutdown` / `ApplyToAISnapshot`  
3. Bind observe-only pointers to existing facades  
4. Wire into `CApplication` timer path only  
5. Keep `may_execute` / `may_modify_risk` / `may_interrupt_trading` false  

## Compile

MetaEditor64 with `/include` = project root. Target: **0 errors**.

## Reference patterns

- Closure: `Include/Phase6/`  
- Prior platform: `Include/Cloud/Deployment/`
