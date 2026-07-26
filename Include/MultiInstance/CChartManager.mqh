//+------------------------------------------------------------------+
//|                                            CChartManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCHART_MANAGER_MQH
#define GM_CCHART_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmInstanceRecord.mqh"
#include "../Core/Version.mqh"
#include "../Logging/CLogger.mqh"

/// @file CChartManager.mqh
/// @brief Tracks the local chart running The Gold Mind AI.

class CGmChartManager
  {
private:
   CGmLogger *m_logger;
   long       m_chart_id;
   string     m_chart_name;
   string     m_symbol;
   string     m_timeframe;
   bool       m_loaded;

   string TfName(const ENUM_TIMEFRAMES tf) const
     {
      string s = EnumToString(tf);
      StringReplace(s, "PERIOD_", "");
      return s;
     }

public:
                     CGmChartManager(void)
                       : m_logger(NULL), m_chart_id(0), m_chart_name(""),
                         m_symbol(""), m_timeframe(""), m_loaded(false)
     {
     }

   void Init(CGmLogger *logger, const string symbol, const ENUM_TIMEFRAMES tf)
     {
      m_logger = logger;
      m_chart_id = ChartID();
      m_symbol = symbol;
      m_timeframe = TfName(tf);
      m_chart_name = StringFormat("%s %s #%I64d", m_symbol, m_timeframe, m_chart_id);
      m_loaded = true;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Chart Loaded | id=%I64d | %s | build=%d",
                                    m_chart_id, m_chart_name, GM_VERSION_BUILD),
                       "ChartManager");
     }

   void Shutdown(void)
     {
      if(m_loaded && m_logger != NULL)
         m_logger.Info(StringFormat("Chart Closed | id=%I64d", m_chart_id), "ChartManager");
      m_loaded = false;
     }

   long ChartId(void) const { return m_chart_id; }
   string ChartName(void) const { return m_chart_name; }
   string Symbol(void) const { return m_symbol; }
   string Timeframe(void) const { return m_timeframe; }
   bool IsLoaded(void) const { return m_loaded; }

   void ApplyToRecord(SGmInstanceRecord &rec) const
     {
      rec.chart_id = m_chart_id;
      rec.chart_name = m_chart_name;
      rec.symbol = m_symbol;
      rec.timeframe = m_timeframe;
      rec.chart_active = (m_loaded && m_chart_id == ChartID());
      rec.ea_version = StringFormat("%s#%d", GM_VERSION_STRING, GM_VERSION_BUILD);
     }
  };

#endif // GM_CCHART_MANAGER_MQH
//+------------------------------------------------------------------+
