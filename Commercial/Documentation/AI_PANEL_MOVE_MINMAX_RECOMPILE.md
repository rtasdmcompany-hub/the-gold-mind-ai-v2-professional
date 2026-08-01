# AI Dynamic panel — move / minimize / maximize

**UI only.** Trading / Risk / Recovery / Money / Entry / Exit / Order logic is not modified.

## Why it still looked frozen

Source already had drag + `[-]`/`[+]` controls, but the **packaged `TheGoldMindAI_Professional.ex5` was not rebuilt** in MetaEditor after those UI changes. MT5 runs the **EX5 binary**, not the `.mqh` source. Until you recompile, the chart keeps the old fixed panel (no AI header button, no drag).

## What 11E.2 UI adds (after compile)

- Brown **header strip** — drag here to move the AI panel  
- Visible **`[-]` / `[+]`** button (same style as main THE GOLD MIND panel)  
- Title shows **`AI DYNAMIC EXEC 11E.2`** + small **drag** hint (confirms new build)  
- Position remembered per symbol/chart via terminal global variables  

## Owner steps (Windows)

1. Pull latest GitHub `main` (or run your local auto-sync).  
2. Open MetaEditor → `Experts/TheGoldMindAI_Professional.mq5` → **Compile** (F7).  
3. Confirm `Experts/TheGoldMindAI_Professional.ex5` timestamp updates.  
4. In MT5: remove EA from chart → Navigator → re-attach `TheGoldMindAI_Professional`.  
5. On the AI panel you should see title **11E.2**, word **drag**, and a **`[-]`** button on the right of the header.  
6. Drag the brown header; click `[-]` to minimize, `[+]` to maximize.

Optional: copy the new EX5 into  
`Commercial/Installer/Professional/inno/payload/ea/` and rebuild the installer ZIP so Downloads ships the new binary.

Cloud/Linux agents **cannot** produce a real MetaTrader EX5; only MetaEditor on Windows can.
