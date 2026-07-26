//+------------------------------------------------------------------+
//|                                          CNewsDataEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CNEWS_DATA_ENGINE_MQH
#define GM_CNEWS_DATA_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CCalendarNewsProvider.mqh"
#include "CStubNewsProviders.mqh"
#include "../../Logging/CLogger.mqh"

/// @brief Aggregates news providers into a standardized event buffer.
class CGmNewsDataEngine
  {
private:
   CGmLogger                  *m_logger;
   CGmCalendarNewsProvider     m_calendar;
   CGmApiNewsProvider          m_api;
   CGmBrokerNewsProvider       m_broker;
   CGmRssNewsProvider          m_rss;
   CGmInstitutionalNewsProvider m_inst;
   CGmSyntheticNewsProvider    m_synth;
   SGmNewsEvent                m_events[GM_NEWS_EVENT_MAX];
   int                         m_count;
   ENUM_GM_NEWS_PROVIDER       m_active;
   bool                        m_ready;

public:
                     CGmNewsDataEngine(void)
                       : m_logger(NULL), m_count(0),
                         m_active(GM_NEWS_PROVIDER_NONE), m_ready(false) {}

   bool Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_calendar.Init();
      m_api.Init();
      m_broker.Init();
      m_rss.Init();
      m_inst.Init();
      m_synth.Init();
      m_count = 0;
      m_active = GM_NEWS_PROVIDER_NONE;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("News Data Engine ready | providers=Calendar+API+Broker+RSS+Inst+Synth",
                       "NewsData");
      return true;
     }

   int Count(void) const { return m_count; }
   ENUM_GM_NEWS_PROVIDER ActiveProvider(void) const { return m_active; }
   SGmNewsEvent At(const int i) const
     {
      SGmNewsEvent e;
      e.Reset();
      if(i >= 0 && i < m_count)
         return m_events[i];
      return e;
     }

   int Refresh(void)
     {
      if(!m_ready)
         return 0;
      m_count = 0;
      const datetime now = TimeCurrent();
      const datetime from_t = now - GM_NEWS_LOOKBACK_HOURS * 3600;
      const datetime to_t = now + GM_NEWS_LOOKAHEAD_HOURS * 3600;

      SGmNewsEvent buf[];
      int n = m_calendar.Fetch(buf, from_t, to_t);
      if(n > 0)
        {
         m_active = GM_NEWS_PROVIDER_CALENDAR;
         Merge(buf, n);
        }
      else
        {
         // Future stubs always return 0 today; synthetic fills monitoring gap
         n = m_api.Fetch(buf, from_t, to_t);
         if(n <= 0) n = m_broker.Fetch(buf, from_t, to_t);
         if(n <= 0) n = m_rss.Fetch(buf, from_t, to_t);
         if(n <= 0) n = m_inst.Fetch(buf, from_t, to_t);
         if(n <= 0) n = m_synth.Fetch(buf, from_t, to_t);
         if(n > 0)
           {
            m_active = (buf[0].provider != GM_NEWS_PROVIDER_NONE)
                       ? buf[0].provider : GM_NEWS_PROVIDER_SYNTHETIC;
            Merge(buf, n);
           }
         else
            m_active = GM_NEWS_PROVIDER_NONE;
        }

      if(m_logger != NULL && m_count > 0)
         m_logger.Info(StringFormat("Event Received | count=%d | provider=%s",
                                    m_count, GmNewsProviderName(m_active)),
                       "NewsData");
      return m_count;
     }

private:
   void Merge(const SGmNewsEvent &buf[], const int n)
     {
      for(int i = 0; i < n && m_count < GM_NEWS_EVENT_MAX; i++)
        {
         if(!buf[i].valid)
            continue;
         m_events[m_count++] = buf[i];
         if(m_logger != NULL)
            m_logger.Debug("Event Received | " + buf[i].name, "NewsData");
        }
     }
  };

#endif // GM_CNEWS_DATA_ENGINE_MQH
//+------------------------------------------------------------------+
