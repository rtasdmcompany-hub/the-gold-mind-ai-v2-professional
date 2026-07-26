//+------------------------------------------------------------------+
//|                                         CErrorClassifier.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CERROR_CLASSIFIER_MQH
#define GM_CERROR_CLASSIFIER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmValidationResult.mqh"
#include "../Logging/CLogger.mqh"

/// @file CErrorClassifier.mqh
/// @brief Classifies validation findings + recommended fixes.

class CGmErrorClassifier
  {
private:
   CGmLogger   *m_logger;
   SGmValError  m_errors[GM_VAL_MAX_ERRORS];
   int          m_count;

   string SeverityName(const ENUM_GM_VAL_SEVERITY sev) const
     {
      switch(sev)
        {
         case GM_VAL_SEV_INFO:      return "INFO";
         case GM_VAL_SEV_WARNING:   return "WARNING";
         case GM_VAL_SEV_MINOR:     return "MINOR";
         case GM_VAL_SEV_MAJOR:     return "MAJOR";
         case GM_VAL_SEV_CRITICAL:  return "CRITICAL";
         case GM_VAL_SEV_PERF:      return "PERFORMANCE";
         case GM_VAL_SEV_RECOVERY:  return "RECOVERY";
        }
      return "UNKNOWN";
     }

public:
                     CGmErrorClassifier(void) : m_logger(NULL), m_count(0)
     {
      for(int i = 0; i < GM_VAL_MAX_ERRORS; i++)
         m_errors[i].Reset();
     }

                    ~CGmErrorClassifier(void) { m_logger = NULL; }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_count = 0;
     }

   void Clear(void)
     {
      m_count = 0;
      for(int i = 0; i < GM_VAL_MAX_ERRORS; i++)
         m_errors[i].Reset();
     }

   int Count(void) const { return m_count; }

   int CountSeverity(const ENUM_GM_VAL_SEVERITY sev) const
     {
      int n = 0;
      for(int i = 0; i < m_count; i++)
         if(m_errors[i].used && m_errors[i].severity == sev)
            n++;
      return n;
     }

   void Add(const ENUM_GM_VAL_SEVERITY sev,
            const string module,
            const string message,
            const string fix)
     {
      if(m_count >= GM_VAL_MAX_ERRORS)
         return;
      m_errors[m_count].severity = sev;
      m_errors[m_count].module = module;
      m_errors[m_count].message = message;
      m_errors[m_count].fix = fix;
      m_errors[m_count].used = true;
      m_count++;

      if(m_logger != NULL)
        {
         const string line = StringFormat("[%s] %s | %s | Fix: %s",
                                          SeverityName(sev), module, message, fix);
         if(sev == GM_VAL_SEV_CRITICAL || sev == GM_VAL_SEV_MAJOR)
            m_logger.Error(line, "ErrorReport");
         else if(sev == GM_VAL_SEV_WARNING || sev == GM_VAL_SEV_PERF || sev == GM_VAL_SEV_RECOVERY)
            m_logger.Warning(line, "ErrorReport");
         else
            m_logger.Info(line, "ErrorReport");
        }
     }

   string Dump(void) const
     {
      string out = StringFormat("Errors=%d Critical=%d Major=%d Minor=%d Warn=%d Perf=%d Recovery=%d\r\n",
                                m_count,
                                CountSeverity(GM_VAL_SEV_CRITICAL),
                                CountSeverity(GM_VAL_SEV_MAJOR),
                                CountSeverity(GM_VAL_SEV_MINOR),
                                CountSeverity(GM_VAL_SEV_WARNING),
                                CountSeverity(GM_VAL_SEV_PERF),
                                CountSeverity(GM_VAL_SEV_RECOVERY));
      for(int i = 0; i < m_count; i++)
        {
         if(!m_errors[i].used)
            continue;
         out += StringFormat("- [%s] %s: %s | Fix: %s\r\n",
                             SeverityName(m_errors[i].severity),
                             m_errors[i].module,
                             m_errors[i].message,
                             m_errors[i].fix);
        }
      return out;
     }
  };

#endif // GM_CERROR_CLASSIFIER_MQH
//+------------------------------------------------------------------+
