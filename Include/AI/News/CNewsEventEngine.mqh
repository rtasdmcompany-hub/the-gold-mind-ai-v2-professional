//+------------------------------------------------------------------+
//|                                         CNewsEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CNEWS_EVENT_ENGINE_MQH
#define GM_CNEWS_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsAnalysisResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmNewsEventEngine
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_NEWS_EVT_LOG_MAX];
   int        m_n;
   bool       m_ready;

   void Push(const ENUM_GM_NEWS_EVENT_TYPE type, const string detail)
     {
      string label = "Info";
      switch(type)
        {
         case GM_NEWS_EVT_ENGINE_STARTED: label = "News Engine Started"; break;
         case GM_NEWS_EVT_RECEIVED:       label = "Event Received"; break;
         case GM_NEWS_EVT_IMPACT:         label = "Impact Classified"; break;
         case GM_NEWS_EVT_REACTION:       label = "Market Reaction Recorded"; break;
         case GM_NEWS_EVT_GOLD:           label = "Gold Event Monitor"; break;
         case GM_NEWS_EVT_DB:             label = "Database Updated"; break;
        }
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_SECONDS),
                                       label, detail);
      if(m_n < GM_NEWS_EVT_LOG_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_NEWS_EVT_LOG_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_NEWS_EVT_LOG_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(label + " | " + detail, "NewsEvent");
     }

public:
                     CGmNewsEventEngine(void)
                       : m_logger(NULL), m_n(0), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_ready = true;
      Push(GM_NEWS_EVT_ENGINE_STARTED, GM_NEWS_AI_VERSION + " | " + GM_NEWS_NO_TRADE_BLOCK);
     }

   int Count(void) const { return m_n; }
   string At(const int i) const
     { return (i >= 0 && i < m_n) ? m_events[i] : ""; }

   void Evaluate(const SGmNewsAnalysisResult &cur, const SGmNewsAnalysisResult &prev)
     {
      if(!m_ready || !cur.valid)
         return;
      if(cur.upcoming.valid &&
         (!prev.valid || prev.upcoming.event_id != cur.upcoming.event_id))
         Push(GM_NEWS_EVT_RECEIVED, cur.upcoming.name);
      Push(GM_NEWS_EVT_IMPACT, GmNewsImpactName(cur.current_impact) +
           StringFormat(" | risk=%.0f", cur.news_risk_score));
      Push(GM_NEWS_EVT_REACTION, cur.reaction.summary);
      Push(GM_NEWS_EVT_GOLD, cur.gold_monitor_summary);
      Push(GM_NEWS_EVT_DB, "history row queued");
     }

   string ExportBody(void) const
     {
      string body = "";
      for(int i = 0; i < m_n; i++)
         body += m_events[i] + "\r\n";
      return body;
     }
  };

#endif // GM_CNEWS_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
