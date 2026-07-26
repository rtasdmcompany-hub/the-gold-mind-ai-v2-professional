//+------------------------------------------------------------------+
//|                                CEconomicCalendarAnalyzer.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CECONOMIC_CALENDAR_ANALYZER_MQH
#define GM_CECONOMIC_CALENDAR_ANALYZER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CNewsDataEngine.mqh"

/// @brief Selects upcoming / high-impact / last-released events.
class CGmEconomicCalendarAnalyzer
  {
public:
   void Analyze(CGmNewsDataEngine &data, SGmNewsAnalysisResult &r)
     {
      r.event_count = data.Count();
      r.active_provider = data.ActiveProvider();
      r.upcoming.Reset();
      r.next_high_impact.Reset();
      r.last_released.Reset();
      r.seconds_until_next = 0;
      r.seconds_until_high = 0;

      const datetime now = TimeCurrent();
      datetime best_up = 0;
      datetime best_hi = 0;
      datetime best_rel = 0;

      for(int i = 0; i < data.Count(); i++)
        {
         const SGmNewsEvent e = data.At(i);
         if(!e.valid)
            continue;

         if(e.event_time >= now)
           {
            if(best_up == 0 || e.event_time < best_up)
              {
               best_up = e.event_time;
               r.upcoming = e;
              }
            if((e.impact == GM_NEWS_IMPACT_HIGH ||
                e.impact == GM_NEWS_IMPACT_VERY_HIGH ||
                e.impact == GM_NEWS_IMPACT_BLACK_SWAN) &&
               (best_hi == 0 || e.event_time < best_hi))
              {
               best_hi = e.event_time;
               r.next_high_impact = e;
              }
           }
         else if(e.status == GM_NEWS_STATUS_RELEASED || e.status == GM_NEWS_STATUS_EXPIRED)
           {
            if(e.event_time > best_rel)
              {
               best_rel = e.event_time;
               r.last_released = e;
              }
           }
        }

      if(r.upcoming.valid)
         r.seconds_until_next = (int)(r.upcoming.event_time - now);
      if(r.next_high_impact.valid)
         r.seconds_until_high = (int)(r.next_high_impact.event_time - now);
     }
  };

#endif // GM_CECONOMIC_CALENDAR_ANALYZER_MQH
//+------------------------------------------------------------------+
