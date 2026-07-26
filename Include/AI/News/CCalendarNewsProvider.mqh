//+------------------------------------------------------------------+
//|                                   CCalendarNewsProvider.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCALENDAR_NEWS_PROVIDER_MQH
#define GM_CCALENDAR_NEWS_PROVIDER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IGmNewsProvider.mqh"

/// @brief MT5 Economic Calendar provider (read-only).
class CGmCalendarNewsProvider : public CGmNewsProviderBase
  {
public:
                     CGmCalendarNewsProvider(void) { m_name = "MT5 Economic Calendar"; }

   virtual ENUM_GM_NEWS_PROVIDER Type(void) const { return GM_NEWS_PROVIDER_CALENDAR; }

   virtual int Fetch(SGmNewsEvent &out[], const datetime from_t, const datetime to_t)
     {
      ArrayResize(out, 0);
      MqlCalendarValue values[];
      const int n = CalendarValueHistory(values, from_t, to_t);
      if(n <= 0)
         return 0;

      const int max_n = MathMin(n, GM_NEWS_EVENT_MAX);
      ArrayResize(out, max_n);
      int written = 0;
      for(int i = 0; i < max_n; i++)
        {
         MqlCalendarEvent ev;
         MqlCalendarCountry country;
         if(!CalendarEventById(values[i].event_id, ev))
            continue;
         if(!CalendarCountryById(ev.country_id, country))
           {
            country.name = "";
            country.currency = "";
           }

         SGmNewsEvent e;
         e.Reset();
         e.event_id = values[i].event_id;
         e.name = ev.name;
         e.country = country.name;
         e.currency = country.currency;
         e.event_time = values[i].time;
         e.previous = values[i].prev_value;
         e.forecast = values[i].forecast_value;
         e.actual = values[i].actual_value;
         e.revision = values[i].revised_prev_value;
         e.provider = GM_NEWS_PROVIDER_CALENDAR;
         e.impact = MapImportance(ev.importance);
         e.status = ClassifyStatus(values[i].time, values[i].actual_value);
         e.valid = true;
         out[written++] = e;
        }
      ArrayResize(out, written);
      return written;
     }

private:
   ENUM_GM_NEWS_IMPACT MapImportance(const ENUM_CALENDAR_EVENT_IMPORTANCE imp)
     {
      if(imp == CALENDAR_IMPORTANCE_HIGH)
         return GM_NEWS_IMPACT_HIGH;
      if(imp == CALENDAR_IMPORTANCE_MODERATE)
         return GM_NEWS_IMPACT_MEDIUM;
      if(imp == CALENDAR_IMPORTANCE_LOW)
         return GM_NEWS_IMPACT_LOW;
      return GM_NEWS_IMPACT_VERY_LOW;
     }

   ENUM_GM_NEWS_EVENT_STATUS ClassifyStatus(const datetime t, const double actual)
     {
      const datetime now = TimeCurrent();
      if(actual != 0.0 || t < now - 60)
        {
         if(t < now - 3600)
            return GM_NEWS_STATUS_EXPIRED;
         return GM_NEWS_STATUS_RELEASED;
        }
      if(t <= now + 300 && t >= now - 300)
         return GM_NEWS_STATUS_LIVE;
      if(t > now)
         return GM_NEWS_STATUS_UPCOMING;
      return GM_NEWS_STATUS_RELEASED;
     }
  };

#endif // GM_CCALENDAR_NEWS_PROVIDER_MQH
//+------------------------------------------------------------------+
