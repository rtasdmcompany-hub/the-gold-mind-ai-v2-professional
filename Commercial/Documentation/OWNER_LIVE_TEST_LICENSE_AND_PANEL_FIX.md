# Owner Live-Test Fix — License Activation + AI Panel

**Date:** 2026-08-01  
**Trigger:** Owner live testing (portal pending + EA running without key + AI panel controls)

---

## Why portal showed “pending”

1. **Generating a key creates status `pending`.** That is correct until activation succeeds.  
2. **Setup.exe previously allowed Finish without a key** (optional checkbox / fail-open). The EA was deployed anyway.  
3. **The EA binary does not gate trading on a commercial key** (licensing is commercial entitlement, not a trade lock). So MT5 can trade even when the portal license is still pending.  
4. If browser “Activate in portal” showed `Activated · device …` but the table stayed pending, the UI was not refreshing after activation (fixed).

---

## What we changed

| Area | Change |
|------|--------|
| Setup wizard (`Program.net48.cs` only) | New **License Activation** step — email + key **required**; portal must return **Active/grace** before install completes; EA deploy blocked otherwise; `/SILENT` requires `TGM_LICENSE_EMAIL` + `TGM_LICENSE_KEY` |
| `Deploy-EA-To-MT5.ps1` | Refuses deploy without `config\license-activation.json` Active/grace |
| Portal `LicenseActionsPanel` | Clarifies Setup is the primary path; `router.refresh()` after create/activate |
| AI Dynamic Engine panel | Movable (drag header) + minimize/maximize `[-]` / `[+]` (UI only) — see `AI_PANEL_MOVE_MINMAX_RECOMPILE.md`; title must show **11E.2** after MetaEditor compile |

Trial and lifetime use the **same** Active rule.

---

## Owner actions required (this environment cannot finish them)

1. **Use the new canonical Setup.exe already rebuilt in-repo**  
   `Commercial/Releases/1.0.0/installer/Setup.exe`  
   (strict license markers embedded; rebuild via `Build-CommercialRelease.ps1` / mono `mcs` replaces in place).

2. **Recompile EX5 in MetaEditor**  
   Open `Experts/TheGoldMindAI_Professional.mq5` → Compile → replace packaged `TheGoldMindAI_Professional.ex5`.  
   Panel move/min/max will not appear until EX5 is rebuilt and re-attached in MT5.

3. **Activate your existing trial key now** (current PC)  
   - Portal → My Licenses → copy key  
   - Run Start Menu → **Activate License**, or:  
     `Activate-License.ps1 -InstallRoot "…\THE GOLD MIND PROFESSIONAL"`  
   - Confirm portal STATUS becomes **active**, ACTIVATED date fills, seats `1/1`.

4. **Promote portal** to production (Vercel) so the refresh/copy fixes are live.

---

## If Setup shows `(400) Bad Request`

Usually **DEVICE_LIMIT_REACHED**: trial seat (1) was already taken by portal **Activate in portal** (`portal-browser-fingerprint`).  
**Fix (server):** Setup activation now **replaces** that soft seat with the real Windows PC. Redeploy portal, then retry Setup with the same email + key.  
**Manual fallback:** Portal → **Devices** → Deactivate the portal device → run Setup again.  
New Setup.exe also shows the real API error text instead of bare “Bad Request”.

## Correct customer flow (after new Setup.exe)

1. Create account + login on Customer Portal  
2. Generate license key (trial or paid) — table shows **pending** until Setup activates it  
3. Run **Setup.exe** → paste **same email + key**  
4. Setup finishes only when portal confirms **Active**  
5. Attach EA in MT5  

---

Trading / Risk / Recovery / Money / Entry / Exit / Order logic: **not modified**.
