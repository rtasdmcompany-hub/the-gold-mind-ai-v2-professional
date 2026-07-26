//+------------------------------------------------------------------+
//|                                                CAIDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_DATABASE_MQH
#define GM_CAI_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "AIConstants.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

/// @file CAIDatabase.mqh
/// @brief Internal AI storage (events/logs/decisions/stats) — infrastructure only.

class CGmAIDatabase
  {
private:
   CGmLogger       *m_logger;
   CGmFileManager  *m_files;
   string           m_file;
   long             m_magic;
   string           m_symbol;

   string           m_logs[GM_AI_LOG_MAX];
   int              m_log_n;
   string           m_decisions[GM_AI_DECISION_MAX];
   int              m_dec_n;
   double           m_confidence_hist[GM_AI_PRED_HIST_MAX];
   int              m_conf_n;
   string           m_predictions[GM_AI_PRED_HIST_MAX];
   int              m_pred_n;
   string           m_recommendations[GM_AI_REC_HIST_MAX];
   int              m_rec_n;

   double           m_stat_collect_us_avg;
   ulong            m_stat_collect_count;
   bool             m_ready;

public:
                     CGmAIDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""),
                         m_magic(0), m_symbol(""),
                         m_log_n(0), m_dec_n(0), m_conf_n(0),
                         m_pred_n(0), m_rec_n(0),
                         m_stat_collect_us_avg(0.0), m_stat_collect_count(0),
                         m_ready(false)
     {
     }

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      m_magic = magic;
      m_symbol = symbol;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%s%I64d_%s.txt", GM_AI_DB_FILE_PREFIX, magic, sym);
      m_log_n = 0;
      m_dec_n = 0;
      m_conf_n = 0;
      m_pred_n = 0;
      m_rec_n = 0;
      m_stat_collect_us_avg = 0.0;
      m_stat_collect_count = 0;
      m_ready = true;
      AddLog("Database Ready");
      if(m_logger != NULL)
         m_logger.Success("AI Database Ready", "AIDatabase");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   bool IsReady(void) const { return m_ready; }

   void AddLog(const string line)
     {
      const string row = TimeToString(TimeCurrent(), TIME_SECONDS) + " | " + line;
      if(m_log_n < GM_AI_LOG_MAX)
        {
         m_logs[m_log_n++] = row;
         return;
        }
      for(int i = 1; i < GM_AI_LOG_MAX; i++)
         m_logs[i - 1] = m_logs[i];
      m_logs[GM_AI_LOG_MAX - 1] = row;
     }

   void AddDecision(const string line)
     {
      if(m_dec_n < GM_AI_DECISION_MAX)
        {
         m_decisions[m_dec_n++] = line;
         return;
        }
      for(int i = 1; i < GM_AI_DECISION_MAX; i++)
         m_decisions[i - 1] = m_decisions[i];
      m_decisions[GM_AI_DECISION_MAX - 1] = line;
     }

   void AddConfidence(const double conf)
     {
      if(m_conf_n < GM_AI_PRED_HIST_MAX)
        {
         m_confidence_hist[m_conf_n++] = conf;
         return;
        }
      for(int i = 1; i < GM_AI_PRED_HIST_MAX; i++)
         m_confidence_hist[i - 1] = m_confidence_hist[i];
      m_confidence_hist[GM_AI_PRED_HIST_MAX - 1] = conf;
     }

   void AddPrediction(const string line)
     {
      if(m_pred_n < GM_AI_PRED_HIST_MAX)
        {
         m_predictions[m_pred_n++] = line;
         return;
        }
      for(int i = 1; i < GM_AI_PRED_HIST_MAX; i++)
         m_predictions[i - 1] = m_predictions[i];
      m_predictions[GM_AI_PRED_HIST_MAX - 1] = line;
     }

   void AddRecommendation(const string line)
     {
      if(m_rec_n < GM_AI_REC_HIST_MAX)
        {
         m_recommendations[m_rec_n++] = line;
         return;
        }
      for(int i = 1; i < GM_AI_REC_HIST_MAX; i++)
         m_recommendations[i - 1] = m_recommendations[i];
      m_recommendations[GM_AI_REC_HIST_MAX - 1] = line;
     }

   void RecordCollectUs(const ulong us)
     {
      m_stat_collect_count++;
      if(m_stat_collect_count == 1)
         m_stat_collect_us_avg = (double)us;
      else
         m_stat_collect_us_avg = (m_stat_collect_us_avg * 0.9) + ((double)us * 0.1);
     }

   double AvgCollectUs(void) const { return m_stat_collect_us_avg; }
   int LogCount(void) const { return m_log_n; }
   int DecisionCount(void) const { return m_dec_n; }
   int PredictionCount(void) const { return m_pred_n; }
   int RecommendationCount(void) const { return m_rec_n; }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "#GM_AI_DATABASE\r\n";
      body += StringFormat("magic=%I64d symbol=%s\r\n", m_magic, m_symbol);
      body += StringFormat("avg_collect_us=%.0f samples=%I64u\r\n",
                           m_stat_collect_us_avg, m_stat_collect_count);
      body += StringFormat("logs=%d decisions=%d preds=%d recs=%d conf=%d\r\n",
                           m_log_n, m_dec_n, m_pred_n, m_rec_n, m_conf_n);
      const int start = MathMax(0, m_log_n - 40);
      for(int i = start; i < m_log_n; i++)
         body += "LOG|" + m_logs[i] + "\r\n";
      m_files.WriteText(m_file, body);
     }
  };

#endif // GM_CAI_DATABASE_MQH
//+------------------------------------------------------------------+
