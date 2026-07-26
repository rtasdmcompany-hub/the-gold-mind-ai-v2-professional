//+------------------------------------------------------------------+
//|                                           CAiKnowledgeBase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_KNOWLEDGE_BASE_MQH
#define GM_CAI_KNOWLEDGE_BASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CPatternRecognition.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmAiKnowledgeBase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_file;
   string          m_entries[GM_LEARN_HIST_MAX];
   string          m_patterns[GM_LEARN_PATTERN_MAX];
   int             m_entry_n;
   int             m_pat_n;
   int             m_prev_size;
   string          m_version;
   bool            m_ready;

public:
                     CGmAiKnowledgeBase(void)
                       : m_logger(NULL), m_files(NULL), m_file(""),
                         m_entry_n(0), m_pat_n(0), m_prev_size(0),
                         m_version(GM_LEARN_KB_VERSION), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file = StringFormat("%sKB_%I64d_%s.txt", GM_LEARN_DB_PREFIX, magic, sym);
      m_entry_n = m_pat_n = m_prev_size = 0;
      m_version = GM_LEARN_KB_VERSION;
      m_ready = true;
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   string Version(void) const { return m_version; }
   int EntryCount(void) const { return m_entry_n; }
   int PatternCount(void) const { return m_pat_n; }
   int Size(void) const { return m_entry_n + m_pat_n; }

   double GrowthPct(void) const
     {
      if(m_prev_size <= 0)
         return (Size() > 0) ? 100.0 : 0.0;
      return GmLearnClamp(100.0 * (double)(Size() - m_prev_size) / (double)m_prev_size);
     }

   void BeginCycle(void)
     {
      m_prev_size = Size();
     }

   void AddEntry(const string line)
     {
      if(!m_ready || StringLen(line) == 0)
         return;
      if(m_entry_n < GM_LEARN_HIST_MAX)
         m_entries[m_entry_n++] = line;
      else
        {
         for(int i = 1; i < GM_LEARN_HIST_MAX; i++)
            m_entries[i - 1] = m_entries[i];
         m_entries[GM_LEARN_HIST_MAX - 1] = line;
        }
     }

   void IngestPatterns(CGmPatternRecognitionEngine &engine)
     {
      for(int i = 0; i < engine.Count(); i++)
        {
         const SGmDetectedPattern p = engine.At(i);
         if(!p.valid)
            continue;
         const string line = StringFormat("%s | str=%.0f | %s",
                                          GmLearnPatternName(p.type), p.strength, p.note);
         // de-dupe by name loosely
         bool exists = false;
         for(int j = 0; j < m_pat_n; j++)
           {
            if(StringFind(m_patterns[j], GmLearnPatternName(p.type)) == 0)
              {
               m_patterns[j] = line;
               exists = true;
               break;
              }
           }
         if(!exists)
           {
            if(m_pat_n < GM_LEARN_PATTERN_MAX)
               m_patterns[m_pat_n++] = line;
           }
         AddEntry(TimeToString(TimeCurrent(), TIME_SECONDS) + " | PAT | " + line);
        }
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL)
         return;
      string body = "=== AI KNOWLEDGE BASE ===\r\n";
      body += "Version=" + m_version + "\r\n";
      body += "POLICY: ANALYTICAL ONLY | NEVER MODIFY STRATEGY\r\n";
      body += "-- PATTERN LIBRARY --\r\n";
      for(int i = 0; i < m_pat_n; i++)
         body += m_patterns[i] + "\r\n";
      body += "-- LEARNING HISTORY --\r\n";
      for(int i = 0; i < m_entry_n; i++)
         body += m_entries[i] + "\r\n";
      m_files.WriteText(m_file, body);
      if(m_logger != NULL)
         m_logger.Info("Knowledge Updated | " + m_file, "LearnKB");
     }
  };

#endif // GM_CAI_KNOWLEDGE_BASE_MQH
//+------------------------------------------------------------------+
