# DOWNLOAD_CENTER_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27

## Customer Portal policy

Customers see **LATEST STABLE VERSION only**.

| Surface | Before | After |
|---------|--------|-------|
| `/portal/downloads` | All channels (stable/rc/development) | Stable-only Download Center |
| `/portal/updates` | Channel switcher | Stable only |
| `GET /api/releases` | All channels | Stable packages only |
| `GET /api/releases/download/[id]` | Any published ID | Non-stable → **403** unless Admin |

## Customer Download Center presents

- Latest Stable Version  
- Windows (64-bit)  
- Download Installer  
- Release Notes  
- SHA256  
- Digital Signature status  

## Admin exclusives

RC, Development, and Nightly remain available in **Admin · Release Management** (`/portal/admin/releases`).

## Verdict

**PASS** — Development/RC builds are not customer-visible.
