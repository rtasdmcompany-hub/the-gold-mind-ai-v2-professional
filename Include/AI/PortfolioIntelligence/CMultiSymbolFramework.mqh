//+------------------------------------------------------------------+
//|                                   CMultiSymbolFramework.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CMULTI_SYMBOL_FRAMEWORK_MQH
#define GM_CMULTI_SYMBOL_FRAMEWORK_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmPortfolioIntelligenceResult.mqh"

class CGmMultiSymbolFramework
  {
private:
   void SetSlot(SGmPortfolioSymbolSlot &s, const string sym,
                const bool enabled, const bool ready, const string status)
     {
      s.symbol = sym;
      s.enabled = enabled;
      s.architecture_ready = ready;
      s.status = status;
     }

public:
   void Build(const string chart_symbol, SGmPortfolioIntelligenceResult &r)
     {
      // Architecture registry — ONLY XAUUSD enabled for live execution
      SetSlot(r.symbols[0], "XAUUSD", true,  true,  "LIVE");
      SetSlot(r.symbols[1], "XAGUSD", false, true,  "DISABLED");
      SetSlot(r.symbols[2], "EURUSD", false, true,  "DISABLED");
      SetSlot(r.symbols[3], "GBPUSD", false, true,  "DISABLED");
      SetSlot(r.symbols[4], "USDJPY", false, true,  "DISABLED");
      SetSlot(r.symbols[5], "US30",   false, true,  "FUTURE");
      SetSlot(r.symbols[6], "NAS100", false, true,  "FUTURE");
      SetSlot(r.symbols[7], "BTCUSD", false, true,  "FUTURE");
      SetSlot(r.symbols[8], "ETHUSD", false, true,  "FUTURE");

      r.symbol_count = GM_PI_SYMBOL_MAX;
      r.enabled_symbol_count = 1;
      r.live_symbol = GM_PI_LIVE_SYMBOL;

      // Soft normalize chart symbol against gold family
      string chart = chart_symbol;
      StringToUpper(chart);
      if(StringFind(chart, "XAU") < 0 && StringFind(chart, "GOLD") < 0)
        {
         // Still XAUUSD-only policy; chart mismatch is advisory warning only
         r.multi_symbol_report = StringFormat(
                                    "Multi-Symbol Framework:\r\nLive=%s | Chart=%s (advisory: Gold Mind executes XAUUSD only)\r\nEnabled=1/%d | AutoEnable=NEVER\r\n",
                                    r.live_symbol, chart_symbol, r.symbol_count);
        }
      else
        {
         r.multi_symbol_report = StringFormat(
                                    "Multi-Symbol Framework:\r\nLive=%s | Chart=%s | Enabled=1/%d\r\nXAG/EUR/GBP/JPY/US30/NAS/BTC/ETH = DISABLED until future phase\r\nAutoEnable=NEVER | %s\r\n",
                                    r.live_symbol, chart_symbol, r.symbol_count, GM_PI_ADVISORY);
        }
     }

   bool IsLiveEnabled(const string sym) const
     {
      string u = sym;
      StringToUpper(u);
      return (StringFind(u, "XAU") >= 0 || u == "XAUUSD" || StringFind(u, "GOLD") >= 0);
     }
  };

#endif // GM_CMULTI_SYMBOL_FRAMEWORK_MQH
//+------------------------------------------------------------------+
