//+------------------------------------------------------------------+
//|                                    CMarketSnapshotEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_SNAPSHOT_ENGINE_MQH
#define GM_CMARKET_SNAPSHOT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketAnalysisResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmMarketSnapshotEngine
  {
private:
   CGmLogger              *m_logger;
   SGmMarketAnalysisResult m_snaps[GM_MKT_SNAP_MAX];
   int                     m_n;
   datetime                m_last_h4;
   bool                    m_ready;

public:
                     CGmMarketSnapshotEngine(void)
                       : m_logger(NULL), m_n(0), m_last_h4(0), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_last_h4 = 0;
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }
   int Count(void) const { return m_n; }

   /// @brief Persist snapshot on new H4 bar only.
   bool MaybeSave(const SGmMarketAnalysisResult &r)
     {
      if(!m_ready || !r.valid)
         return false;
      const datetime h4 = iTime(r.symbol, PERIOD_H4, 0);
      if(h4 <= 0 || h4 == m_last_h4)
         return false;
      m_last_h4 = h4;

      if(m_n < GM_MKT_SNAP_MAX)
         m_snaps[m_n++] = r;
      else
        {
         for(int i = 1; i < GM_MKT_SNAP_MAX; i++)
            m_snaps[i - 1] = m_snaps[i];
         m_snaps[GM_MKT_SNAP_MAX - 1] = r;
        }

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Snapshot Saved | H4=%s | trend=%s | conf=%.1f",
                                    TimeToString(h4, TIME_DATE | TIME_MINUTES),
                                    GmMktDirName(r.direction), r.confidence),
                       "MktSnapshot");
      return true;
     }

   bool GetLatest(SGmMarketAnalysisResult &out) const
     {
      out.Reset();
      if(m_n <= 0)
         return false;
      out = m_snaps[m_n - 1];
      return out.valid;
     }
  };

#endif // GM_CMARKET_SNAPSHOT_ENGINE_MQH
//+------------------------------------------------------------------+
