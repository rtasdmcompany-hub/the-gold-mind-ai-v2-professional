//+------------------------------------------------------------------+
//|                                        CGoldEventMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CGOLD_EVENT_MONITOR_MQH
#define GM_CGOLD_EVENT_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CNewsDataEngine.mqh"

/// @brief XAUUSD-focused event relevance — impact estimates only, never trades.
class CGmGoldEventMonitor
  {
public:
   void Analyze(CGmNewsDataEngine &data, SGmNewsAnalysisResult &r)
     {
      r.gold_monitor_active = true;
      r.gold_event_count = 0;
      string names = "";

      for(int i = 0; i < data.Count(); i++)
        {
         SGmNewsEvent e = data.At(i);
         if(!e.valid)
            continue;
         e.gold_relevant = IsGoldRelevant(e);
         if(!e.gold_relevant)
            continue;
         r.gold_event_count++;
         if(StringLen(names) > 0)
            names += "; ";
         names += e.name;

         if(r.upcoming.valid && r.upcoming.event_id == e.event_id)
            r.upcoming.gold_relevant = true;
         if(r.next_high_impact.valid && r.next_high_impact.event_id == e.event_id)
            r.next_high_impact.gold_relevant = true;
         if(r.last_released.valid && r.last_released.event_id == e.event_id)
            r.last_released.gold_relevant = true;
        }

      if(r.gold_event_count == 0)
         r.gold_monitor_summary = "No gold-sensitive events in window";
      else
         r.gold_monitor_summary = StringFormat("%d gold-sensitive | %s",
                                               r.gold_event_count,
                                               Shorten(names, 48));
     }

private:
   bool IsGoldRelevant(const SGmNewsEvent &e)
     {
      string cur = e.currency;
      StringToUpper(cur);
      if(cur == "USD" || cur == "XAU" || cur == "EUR")
        {
         // EUR only if high+ (ECB can move gold via USD/DXY proxy)
         if(cur == "EUR" && (int)e.impact < (int)GM_NEWS_IMPACT_HIGH)
            return false;
         return true;
        }

      string n = e.name;
      StringToUpper(n);
      if(StringFind(n, "FED") >= 0 || StringFind(n, "FOMC") >= 0 ||
         StringFind(n, "INTEREST RATE") >= 0 || StringFind(n, "CPI") >= 0 ||
         StringFind(n, "INFLATION") >= 0 || StringFind(n, "NFP") >= 0 ||
         StringFind(n, "NONFARM") >= 0 || StringFind(n, "EMPLOYMENT") >= 0 ||
         StringFind(n, "PAYROLL") >= 0 || StringFind(n, "GEOPOLIT") >= 0 ||
         StringFind(n, "RISK") >= 0 || StringFind(n, "GOLD") >= 0 ||
         StringFind(n, "CENTRAL BANK") >= 0 || StringFind(n, "PCE") >= 0 ||
         StringFind(n, "CORE CPI") >= 0 || StringFind(n, "GDP") >= 0)
         return true;
      return false;
     }

   string Shorten(const string s, const int max_len)
     {
      if(StringLen(s) <= max_len)
         return s;
      return StringSubstr(s, 0, max_len - 3) + "...";
     }
  };

#endif // GM_CGOLD_EVENT_MONITOR_MQH
//+------------------------------------------------------------------+
