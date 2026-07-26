//+------------------------------------------------------------------+
//|                                   CVolatilityEventEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CVOLATILITY_EVENT_ENGINE_MQH
#define GM_CVOLATILITY_EVENT_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmVolatilityAnalysisResult.mqh"
#include "../../Logging/CLogger.mqh"

class CGmVolatilityEventEngine
  {
private:
   CGmLogger *m_logger;
   string     m_events[GM_VOL_EVENT_MAX];
   int        m_n;
   ENUM_GM_MARKET_ENERGY m_prev_energy;
   bool       m_ready;

   void Push(const ENUM_GM_VOL_EVENT type, const string detail)
     {
      const string line = StringFormat("%s | %s | %s",
                                       TimeToString(TimeCurrent(), TIME_SECONDS),
                                       GmVolEventName(type), detail);
      if(m_n < GM_VOL_EVENT_MAX)
         m_events[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_VOL_EVENT_MAX; i++)
            m_events[i - 1] = m_events[i];
         m_events[GM_VOL_EVENT_MAX - 1] = line;
        }
      if(m_logger != NULL)
         m_logger.Info(GmVolEventName(type) + " | " + detail, "VolEvent");
     }

public:
                     CGmVolatilityEventEngine(void)
                       : m_logger(NULL), m_n(0),
                         m_prev_energy(GM_ENERGY_UNKNOWN), m_ready(false) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_n = 0;
      m_prev_energy = GM_ENERGY_UNKNOWN;
      m_ready = true;
     }

   int Count(void) const { return m_n; }
   string At(const int i) const
     {
      return (i >= 0 && i < m_n) ? m_events[i] : "";
     }

   void Evaluate(const SGmVolatilityAnalysisResult &cur,
                 const SGmVolatilityAnalysisResult &prev)
     {
      if(!m_ready || !cur.valid)
         return;

      Push(GM_VOL_EVT_ATR_UPDATED, StringFormat("ATR=%.5f | %s",
                                                cur.atr14, GmAtrTrendName(cur.atr_trend)));
      Push(GM_VOL_EVT_VOL_UPDATED, StringFormat("rel=%.0f | stab=%.0f",
                                                cur.relative_vol, cur.vol_stability));
      Push(GM_VOL_EVT_ENERGY_UPDATED, StringFormat("%s | %.0f",
                                                   GmEnergyName(cur.energy), cur.energy_score));
      Push(GM_VOL_EVT_RANGE_UPDATED, StringFormat("H4=%.5f | next=%.5f",
                                                  cur.range_h4, cur.expected_next_range));
      Push(GM_VOL_EVT_PROB_UPDATED, StringFormat("large=%.0f | break=%.0f",
                                                 cur.prob_large_move, cur.prob_breakout));

      if(cur.atr_expansion && (!prev.valid || !prev.atr_expansion))
         Push(GM_VOL_EVT_EXPANSION, "ATR Expansion Detected");
      if(cur.atr_compression && (!prev.valid || !prev.atr_compression))
         Push(GM_VOL_EVT_COMPRESSION, "ATR Compression Detected");

      if(prev.valid &&
         (int)cur.energy >= (int)GM_ENERGY_EXTREME &&
         (int)m_prev_energy < (int)GM_ENERGY_EXTREME)
         Push(GM_VOL_EVT_ENERGY_SPIKE, GmEnergyName(cur.energy));

      m_prev_energy = cur.energy;
     }

   string ExportBody(void) const
     {
      string body = "";
      for(int i = 0; i < m_n; i++)
         body += m_events[i] + "\r\n";
      return body;
     }
  };

#endif // GM_CVOLATILITY_EVENT_ENGINE_MQH
//+------------------------------------------------------------------+
