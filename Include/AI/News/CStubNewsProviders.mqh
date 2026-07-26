//+------------------------------------------------------------------+
//|                                      CStubNewsProviders.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSTUB_NEWS_PROVIDERS_MQH
#define GM_CSTUB_NEWS_PROVIDERS_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "IGmNewsProvider.mqh"

/// @brief Future News API provider stub — ready for Sprint 6+ wiring.
class CGmApiNewsProvider : public CGmNewsProviderBase
  {
public:
                     CGmApiNewsProvider(void) { m_name = "News API (stub)"; }
   virtual ENUM_GM_NEWS_PROVIDER Type(void) const { return GM_NEWS_PROVIDER_API; }
   virtual int Fetch(SGmNewsEvent &out[], const datetime from_t, const datetime to_t)
     { ArrayResize(out, 0); return 0; }
  };

/// @brief Future Broker News Feed stub.
class CGmBrokerNewsProvider : public CGmNewsProviderBase
  {
public:
                     CGmBrokerNewsProvider(void) { m_name = "Broker News Feed (stub)"; }
   virtual ENUM_GM_NEWS_PROVIDER Type(void) const { return GM_NEWS_PROVIDER_BROKER; }
   virtual int Fetch(SGmNewsEvent &out[], const datetime from_t, const datetime to_t)
     { ArrayResize(out, 0); return 0; }
  };

/// @brief Future RSS Feed stub.
class CGmRssNewsProvider : public CGmNewsProviderBase
  {
public:
                     CGmRssNewsProvider(void) { m_name = "RSS Feed (stub)"; }
   virtual ENUM_GM_NEWS_PROVIDER Type(void) const { return GM_NEWS_PROVIDER_RSS; }
   virtual int Fetch(SGmNewsEvent &out[], const datetime from_t, const datetime to_t)
     { ArrayResize(out, 0); return 0; }
  };

/// @brief Future Institutional News Service stub.
class CGmInstitutionalNewsProvider : public CGmNewsProviderBase
  {
public:
                     CGmInstitutionalNewsProvider(void) { m_name = "Institutional News (stub)"; }
   virtual ENUM_GM_NEWS_PROVIDER Type(void) const { return GM_NEWS_PROVIDER_INSTITUTIONAL; }
   virtual int Fetch(SGmNewsEvent &out[], const datetime from_t, const datetime to_t)
     { ArrayResize(out, 0); return 0; }
  };

/// @brief Synthetic USD/Gold schedule fallback when calendar returns empty.
class CGmSyntheticNewsProvider : public CGmNewsProviderBase
  {
public:
                     CGmSyntheticNewsProvider(void) { m_name = "Synthetic Gold Schedule"; }
   virtual ENUM_GM_NEWS_PROVIDER Type(void) const { return GM_NEWS_PROVIDER_SYNTHETIC; }

   virtual int Fetch(SGmNewsEvent &out[], const datetime from_t, const datetime to_t)
     {
      // Placeholder schedule markers for monitoring UX when calendar is offline.
      // ANALYSIS ONLY — does not affect trading.
      ArrayResize(out, 0);
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      // Next weekday 15:30 server-ish NFP/CPI style placeholder only on empty weeks
      datetime next = StringToTime(StringFormat("%04d.%02d.%02d 15:30",
                                               dt.year, dt.mon, MathMin(28, dt.day + ((5 - dt.day_of_week + 7) % 7))));
      if(next < from_t || next > to_t)
         return 0;

      ArrayResize(out, 1);
      out[0].Reset();
      out[0].event_id = -1;
      out[0].name = "Synthetic USD High-Impact Window";
      out[0].country = "United States";
      out[0].currency = "USD";
      out[0].event_time = next;
      out[0].impact = GM_NEWS_IMPACT_HIGH;
      out[0].status = GM_NEWS_STATUS_UPCOMING;
      out[0].provider = GM_NEWS_PROVIDER_SYNTHETIC;
      out[0].gold_relevant = true;
      out[0].impact_confidence = 40.0;
      out[0].valid = true;
      return 1;
     }
  };

#endif // GM_CSTUB_NEWS_PROVIDERS_MQH
//+------------------------------------------------------------------+
