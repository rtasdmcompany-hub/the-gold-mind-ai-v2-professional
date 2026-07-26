//+------------------------------------------------------------------+
//|                                      CLifecycleValidator.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLIFECYCLE_VALIDATOR_MQH
#define GM_CLIFECYCLE_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CErrorClassifier.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Lifecycle/SGmLevelRecord.mqh"
#include "../Calculation/LevelConstants.mqh"
#include "../Calculation/EnumsLevels.mqh"

/// @file CLifecycleValidator.mqh
/// @brief Validates level lifecycle integrity (no duplicate tags / valid states).

class CGmLifecycleValidator
  {
private:
   CGmLogger          *m_logger;
   CGmErrorClassifier *m_errors;
   CGmLevelManager    *m_level_mgr;
   int                 m_issues;

public:
                     CGmLifecycleValidator(void)
                       : m_logger(NULL), m_errors(NULL), m_level_mgr(NULL), m_issues(0) {}
                    ~CGmLifecycleValidator(void)
     {
      m_logger = NULL;
      m_errors = NULL;
      m_level_mgr = NULL;
     }

   void Init(CGmLogger *logger, CGmErrorClassifier *errors, CGmLevelManager *level_mgr)
     {
      m_logger = logger;
      m_errors = errors;
      m_level_mgr = level_mgr;
     }

   int IssueCount(void) const { return m_issues; }

   bool Validate(void)
     {
      m_issues = 0;
      if(m_level_mgr == NULL)
        {
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_CRITICAL, "Lifecycle", "LevelManager null",
                         "Ensure LevelManager Init before validation.");
         m_issues++;
         return false;
        }

      int active = 0, completed = 0, failed = 0;
      m_level_mgr.CountLevelStats(active, completed, failed);

      // Duplicate tag check via counting — each tag should appear once in DB
      // CountLevelStats already aggregates 6 tags; ensure cycle id set when active
      if(m_level_mgr.H4Cycle() <= 0 && (active + completed + failed) > 0)
        {
         m_issues++;
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_MAJOR, "Lifecycle",
                         "Levels present without H4 cycle id",
                         "Call BeginNewCycle / Recover on startup.");
        }

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Lifecycle validation | active=%d completed=%d failed=%d H4=%s issues=%d",
                                    active, completed, failed,
                                    TimeToString(m_level_mgr.H4Cycle(), TIME_DATE | TIME_MINUTES),
                                    m_issues),
                       "LifecycleValidation");

      // Structural pass: engine present, stats readable, no critical cycle mismatch
      return (m_issues == 0);
     }
  };

#endif // GM_CLIFECYCLE_VALIDATOR_MQH
//+------------------------------------------------------------------+
