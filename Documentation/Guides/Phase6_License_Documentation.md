# Phase 6 — License Documentation

**Module:** `Include/Cloud/Identity/` · Facade `CGmEnterpriseIdentityEngine`

## Features

- License validation & health  
- User authentication session architecture  
- Device activation / history  
- Grace period & offline cache (trading allowed by design during grace/offline)

## Rule

License platform **never interrupts** live trading. Grace/offline paths keep Core execution authority intact.
