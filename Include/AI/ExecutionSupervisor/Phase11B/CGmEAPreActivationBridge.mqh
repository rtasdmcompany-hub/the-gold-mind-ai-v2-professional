//+------------------------------------------------------------------+
//|                    CGmEAPreActivationBridge.mqh                  |
//|  EA integration bridge — Phase 11E dynamic engine (thin hooks)   |
//|  Keeps GmP11B_* API so EA trading logic wiring stays unchanged   |
//+------------------------------------------------------------------+
#ifndef GM_CGM_EA_PRE_ACTIVATION_BRIDGE_MQH
#define GM_CGM_EA_PRE_ACTIVATION_BRIDGE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "..\Phase11E\CPhase11EDynamicExecutionEngine.mqh"

//--- Owner-configurable AI Execution inputs (Phase 11E evolves 11B)
input group "--- PHASE 11E Dynamic AI Pre-Activation Engine ---"
input bool           P11B_Enable_Supervisor        = true;  // Enable Dynamic AI Execution Engine
input double         P11B_Max_Lot_Increase_Pct     = 20.0;  // Max lot increase vs original (%)
input double         P11B_Max_Lot_Reduction_Pct    = 50.0;  // Max lot reduction vs original (%)
input int            P11B_Max_Freeze_Minutes       = 30;    // Max freeze duration (minutes)
input bool           P11B_Emergency_Cancel         = true;  // Cancel pendings below 40 confidence
input bool           P11B_News_Protection          = true;  // News/session protection scoring
input bool           P11B_Broker_Protection        = true;  // Broker quality failsafe
input bool           P11B_Weekend_Protection       = true;  // Weekend protection scoring
input bool           P11E_Dynamic_Lot_Monitor      = true;  // Continuously modify pending lots pre-activation

static CPhase11EDynamicExecutionEngine g_p11e;

void GmP11B_OnInit(const ulong magic, const double maxLotCap, const int atrHandle, const int panelX, const int panelY)
  {
   g_p11e.Configure(magic, maxLotCap, atrHandle,
                    P11B_Max_Lot_Increase_Pct, P11B_Max_Lot_Reduction_Pct, P11B_Max_Freeze_Minutes,
                    P11B_Emergency_Cancel, P11B_News_Protection, P11B_Broker_Protection, P11B_Weekend_Protection,
                    P11B_Enable_Supervisor, P11E_Dynamic_Lot_Monitor);
   if(P11B_Enable_Supervisor)
      g_p11e.InitPanel(panelX, panelY + 310);
  }

void GmP11B_OnDeinit(void)
  {
   g_p11e.DestroyPanel();
  }

void GmP11B_OnTick(void)
  {
   g_p11e.OnTickMonitor();
  }

void GmP11B_OnTradeTransaction(const MqlTradeTransaction &trans)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal > 0)
     {
      if(HistoryDealSelect(trans.deal))
        {
         const long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
         if(entry == DEAL_ENTRY_IN)
            g_p11e.OnPositionActivated(HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID));
        }
     }
  }

double GmP11B_AdjustLot(const double engineLots, const int levelIndex, const string comment, const bool isBuy)
  {
   return g_p11e.AdjustLotForPlacement(engineLots, levelIndex, comment, isBuy);
  }

bool GmP11B_AllowPlacement(const string comment, const int levelIndex)
  {
   return g_p11e.AllowPlacement(comment, levelIndex);
  }

void GmP11B_RegisterPlaced(const ulong ticket, const string comment, const int levelIndex)
  {
   g_p11e.RegisterPlacedOrder(ticket, comment, levelIndex);
  }

void GmP11B_UpdatePanel(const int panelX, const int panelY)
  {
   if(!P11B_Enable_Supervisor)
      return;
   g_p11e.UpdatePanel(panelX, panelY);
  }

bool GmP11B_IsActive(void)
  {
   return g_p11e.IsSupervisorActive();
  }

#endif // GM_CGM_EA_PRE_ACTIVATION_BRIDGE_MQH
//+------------------------------------------------------------------+
