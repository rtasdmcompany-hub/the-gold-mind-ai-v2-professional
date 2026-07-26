//+------------------------------------------------------------------+
//|                                           CAICoreDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_CORE_DATABASE_MQH
#define GM_CAI_CORE_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3AIConstants.mqh"
#include "SGmAIBusSnapshot.mqh"
#include "CAIDecisionQueue.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAICoreDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   long            m_magic;
   string          m_symbol;
   string          m_sessions[64];
   int             m_sess_n;
   string          m_analysis[GM_AI_CORE_EVENT_MAX];
   int             m_an_n;
   string          m_learning[GM_AI_CORE_MEM_MAX];
   int             m_learn_n;
   string          m_predictions[GM_AI_CORE_MEM_MAX];
   int             m_pred_n;
   double          m_confidence_hist[GM_AI_CORE_MEM_MAX];
   int             m_conf_n;
   bool            m_ready;

   void PushLine(string &arr[], int &n, const int maxn, const string line)
     {
      if(n < maxn)
         arr[n++] = line;
      else
        {
         for(int i = 1; i < maxn; i++)
            arr[i - 1] = arr[i];
         arr[maxn - 1] = line;
        }
     }

public:
                     CGmAICoreDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""),
                         m_magic(0), m_symbol(""),
                         m_sess_n(0), m_an_n(0), m_learn_n(0),
                         m_pred_n(0), m_conf_n(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      m_magic = magic;
      m_symbol = symbol;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_AI_CORE_DB_PREFIX, magic, sym);
      m_sess_n = m_an_n = m_learn_n = m_pred_n = m_conf_n = 0;
      m_ready = true;
      RecordSession("AI Session Started");
      if(m_logger != NULL)
         m_logger.Success("AI Core Database ready", "AICoreDB");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }

   void RecordSession(const string line)
     {
      if(m_ready)
         PushLine(m_sessions, m_sess_n, 64, TimeToString(TimeCurrent(), TIME_SECONDS) + " | " + line);
     }

   void RecordAnalysis(const string line)
     {
      if(m_ready)
         PushLine(m_analysis, m_an_n, GM_AI_CORE_EVENT_MAX, line);
     }

   void RecordLearning(const string line)
     {
      if(m_ready)
         PushLine(m_learning, m_learn_n, GM_AI_CORE_MEM_MAX, line);
     }

   void RecordPrediction(const string line)
     {
      if(m_ready)
         PushLine(m_predictions, m_pred_n, GM_AI_CORE_MEM_MAX, line);
     }

   void RecordConfidence(const double c)
     {
      if(!m_ready)
         return;
      if(m_conf_n < GM_AI_CORE_MEM_MAX)
         m_confidence_hist[m_conf_n++] = c;
      else
        {
         for(int i = 1; i < GM_AI_CORE_MEM_MAX; i++)
            m_confidence_hist[i - 1] = m_confidence_hist[i];
         m_confidence_hist[GM_AI_CORE_MEM_MAX - 1] = c;
        }
     }

   void RecordMarketSnapshot(const SGmAIBusSnapshot &s)
     {
      if(!m_ready || !s.valid)
         return;
      RecordAnalysis(StringFormat("SNAP | %s | eq=%.2f dd=%.1f open=%d wr=%.1f",
                                  s.symbol, s.equity, s.current_dd_pct,
                                  s.open_positions, s.overall_win_rate));
     }

   void RecordDecision(const SGmAIDecisionItem &d)
     {
      if(!m_ready)
         return;
      RecordAnalysis(StringFormat("DECISION | %s | conf=%.1f | %s | advisory=%d",
                                  d.kind, d.confidence, d.reason, d.advisory_only ? 1 : 0));
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "";
      body += "=== AI CORE DATABASE ===\r\n";
      body += StringFormat("magic=%I64d symbol=%s\r\n", m_magic, m_symbol);
      body += "## Sessions\r\n";
      for(int i = 0; i < m_sess_n; i++)
         body += m_sessions[i] + "\r\n";
      body += "## Analysis\r\n";
      for(int i = 0; i < m_an_n; i++)
         body += m_analysis[i] + "\r\n";
      body += "## Learning\r\n";
      for(int i = 0; i < m_learn_n; i++)
         body += m_learning[i] + "\r\n";
      body += "## Predictions\r\n";
      for(int i = 0; i < m_pred_n; i++)
         body += m_predictions[i] + "\r\n";
      body += "ANALYSIS ONLY — no trade execution stored\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CAI_CORE_DATABASE_MQH
//+------------------------------------------------------------------+
