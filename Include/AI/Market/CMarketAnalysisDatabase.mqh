//+------------------------------------------------------------------+
//|                                 CMarketAnalysisDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_ANALYSIS_DATABASE_MQH
#define GM_CMARKET_ANALYSIS_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmMarketAnalysisResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmMarketAnalysisDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_analysis[GM_MKT_HIST_MAX];
   string          m_trends[GM_MKT_HIST_MAX];
   string          m_vols[GM_MKT_HIST_MAX];
   string          m_patterns[GM_MKT_HIST_MAX];
   double          m_conf[GM_MKT_HIST_MAX];
   int             m_an, m_tr, m_vo, m_pa, m_cf;
   bool            m_ready;

   void PushS(string &arr[], int &n, const string line)
     {
      if(n < GM_MKT_HIST_MAX)
         arr[n++] = line;
      else
        {
         for(int i = 1; i < GM_MKT_HIST_MAX; i++)
            arr[i - 1] = arr[i];
         arr[GM_MKT_HIST_MAX - 1] = line;
        }
     }

   void PushD(double &arr[], int &n, const double v)
     {
      if(n < GM_MKT_HIST_MAX)
         arr[n++] = v;
      else
        {
         for(int i = 1; i < GM_MKT_HIST_MAX; i++)
            arr[i - 1] = arr[i];
         arr[GM_MKT_HIST_MAX - 1] = v;
        }
     }

public:
                     CGmMarketAnalysisDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""),
                         m_an(0), m_tr(0), m_vo(0), m_pa(0), m_cf(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_MKT_DB_PREFIX, magic, sym);
      m_an = m_tr = m_vo = m_pa = m_cf = 0;
      m_ready = true;
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   void Record(const SGmMarketAnalysisResult &r)
     {
      if(!m_ready || !r.valid)
         return;
      const string ts = TimeToString(r.stamped_at, TIME_SECONDS);
      PushS(m_analysis, m_an,
            StringFormat("%s | %s | %s | conf=%.1f | %s",
                         ts, GmMktConditionName(r.condition),
                         GmMktDirName(r.direction), r.confidence, r.insight));
      PushS(m_trends, m_tr,
            StringFormat("%s | %s | str=%.0f | %s",
                         ts, GmMktDirName(r.direction), r.trend_strength,
                         GmMktStructName(r.structure)));
      PushS(m_vols, m_vo,
            StringFormat("%s | atr=%.5f | ratio=%.2f | exp=%d",
                         ts, r.atr14, r.volatility_ratio, r.expansion ? 1 : 0));
      PushS(m_patterns, m_pa,
            StringFormat("%s | %s", ts, GmMktPatternName(r.pattern)));
      PushD(m_conf, m_cf, r.confidence);
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== AI MARKET ANALYSIS DATABASE ===\r\n";
      body += "## Analysis\r\n";
      for(int i = 0; i < m_an; i++) body += m_analysis[i] + "\r\n";
      body += "## Trends\r\n";
      for(int i = 0; i < m_tr; i++) body += m_trends[i] + "\r\n";
      body += "## Volatility\r\n";
      for(int i = 0; i < m_vo; i++) body += m_vols[i] + "\r\n";
      body += "## Patterns\r\n";
      for(int i = 0; i < m_pa; i++) body += m_patterns[i] + "\r\n";
      body += "ANALYSIS ONLY\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CMARKET_ANALYSIS_DATABASE_MQH
//+------------------------------------------------------------------+
