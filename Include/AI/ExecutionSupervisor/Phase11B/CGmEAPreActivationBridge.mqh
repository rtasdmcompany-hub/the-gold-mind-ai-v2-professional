//+------------------------------------------------------------------+
//|                    CGmEAPreActivationBridge.mqh                  |
//|  EA integration bridge — Phase 11E REMOVED from strategy          |
//|  GmP11B_* API kept as pass-through so EA wiring still compiles   |
//+------------------------------------------------------------------+
#ifndef GM_CGM_EA_PRE_ACTIVATION_BRIDGE_MQH
#define GM_CGM_EA_PRE_ACTIVATION_BRIDGE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

// Phase 11E Dynamic AI Execution Engine is permanently disabled for this product.
// Stubs below never change lots, never freeze/cancel, never draw the AI panel.

#ifndef TGM_AI_PANEL_PREFIX
#define TGM_AI_PANEL_PREFIX "TGM_AI_"
#endif

void GmP11B_WipeLegacyAiPanelObjects(void)
  {
   const long chartId = ChartID();
   for(int i = ObjectsTotal(chartId, 0, -1) - 1; i >= 0; i--)
     {
      const string name = ObjectName(chartId, i, 0, -1);
      if(StringFind(name, TGM_AI_PANEL_PREFIX) == 0)
         ObjectDelete(chartId, name);
     }
  }

void GmP11B_OnInit(const ulong magic, const double maxLotCap, const int atrHandle, const int panelX, const int panelY)
  {
   // Intentionally empty: 11E engine not constructed.
   GmP11B_WipeLegacyAiPanelObjects();
   Print("TGM [P11E]: Dynamic AI Execution Engine DISABLED (removed from strategy).");
  }

void GmP11B_OnDeinit(void)
  {
   GmP11B_WipeLegacyAiPanelObjects();
  }

void GmP11B_OnTick(void)
  {
  }

void GmP11B_OnTradeTransaction(const MqlTradeTransaction &trans)
  {
  }

double GmP11B_AdjustLot(const double engineLots, const int levelIndex, const string comment, const bool isBuy)
  {
   return engineLots; // never scale lots
  }

bool GmP11B_AllowPlacement(const string comment, const int levelIndex)
  {
   return true; // never freeze / block placement
  }

void GmP11B_RegisterPlaced(const ulong ticket, const string comment, const int levelIndex)
  {
  }

void GmP11B_UpdatePanel(const int panelX, const int panelY)
  {
   GmP11B_WipeLegacyAiPanelObjects(); // keep chart clean if old objects linger
  }

bool GmP11B_OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   return false;
  }

bool GmP11B_IsActive(void)
  {
   return false;
  }

#endif // GM_CGM_EA_PRE_ACTIVATION_BRIDGE_MQH
//+------------------------------------------------------------------+
