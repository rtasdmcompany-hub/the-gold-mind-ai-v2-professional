//+------------------------------------------------------------------+
//|                                   CDataConsistencyChecker.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CDATA_CONSISTENCY_CHECKER_MQH
#define GM_CDATA_CONSISTENCY_CHECKER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "CErrorClassifier.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Trading/SGmTradeRecord.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "../Core/TradingRules.mqh"

/// @file CDataConsistencyChecker.mqh
/// @brief Detects missing / duplicate registry & session inconsistencies.

class CGmDataConsistencyChecker
  {
private:
   CGmLogger          *m_logger;
   CGmErrorClassifier *m_errors;
   CGmTradeRegistry   *m_registry;
   CGmLevelManager    *m_level_mgr;
   CGmH4SessionEngine *m_h4_session;
   long                m_magic;
   int                 m_issues;

public:
                     CGmDataConsistencyChecker(void)
                       : m_logger(NULL), m_errors(NULL), m_registry(NULL),
                         m_level_mgr(NULL), m_h4_session(NULL), m_magic(0), m_issues(0)
     {
     }

                    ~CGmDataConsistencyChecker(void)
     {
      m_logger = NULL;
      m_errors = NULL;
      m_registry = NULL;
      m_level_mgr = NULL;
      m_h4_session = NULL;
     }

   void Init(CGmLogger *logger,
             CGmErrorClassifier *errors,
             CGmTradeRegistry *registry,
             CGmLevelManager *level_mgr,
             CGmH4SessionEngine *h4_session,
             const long magic)
     {
      m_logger = logger;
      m_errors = errors;
      m_registry = registry;
      m_level_mgr = level_mgr;
      m_h4_session = h4_session;
      m_magic = magic;
     }

   int IssueCount(void) const { return m_issues; }

   bool Check(void)
     {
      m_issues = 0;

      if(m_magic == 0 || m_magic == GM_MAGIC_MANUAL_TRADE)
        {
         m_issues++;
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_CRITICAL, "Consistency", "Invalid Magic Number",
                         "Set unique non-zero Magic != manual(0).");
        }

      if(m_registry != NULL)
        {
         const int n = m_registry.Count();
         for(int i = 0; i < n; i++)
           {
            SGmTradeRecord a;
            if(!m_registry.GetAt(i, a) || !a.used)
               continue;
            if(a.trade_id == 0)
              {
               m_issues++;
               if(m_errors != NULL)
                  m_errors.Add(GM_VAL_SEV_MAJOR, "Consistency",
                               "Trade registry row missing Trade ID",
                               "Rebuild registry from terminal comments.");
              }
            if(a.magic != m_magic)
              {
               m_issues++;
               if(m_errors != NULL)
                  m_errors.Add(GM_VAL_SEV_CRITICAL, "Consistency",
                               StringFormat("Foreign magic in registry | %I64d", a.magic),
                               "Purge foreign records; never manage other Magics.");
              }
            // Duplicate trade_id scan
            for(int j = i + 1; j < n; j++)
              {
               SGmTradeRecord b;
               if(!m_registry.GetAt(j, b) || !b.used)
                  continue;
               if(a.trade_id > 0 && a.trade_id == b.trade_id)
                 {
                  m_issues++;
                  if(m_errors != NULL)
                     m_errors.Add(GM_VAL_SEV_CRITICAL, "Consistency",
                                  StringFormat("Duplicate Trade ID %I64u", a.trade_id),
                                  "Remove duplicate registry row; Trade IDs must be unique.");
                 }
               if(a.ticket > 0 && a.ticket == b.ticket &&
                  a.status == GM_TRADE_STATUS_ACTIVE && b.status == GM_TRADE_STATUS_ACTIVE)
                 {
                  m_issues++;
                  if(m_errors != NULL)
                     m_errors.Add(GM_VAL_SEV_MAJOR, "Consistency",
                                  StringFormat("Duplicate active ticket %I64u", a.ticket),
                                  "Keep single active registry entry per ticket.");
                 }
              }
           }
        }
      else
        {
         m_issues++;
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_CRITICAL, "Consistency", "Trade Registry null",
                         "Initialize TradeRegistry before validation.");
        }

      if(m_level_mgr == NULL)
        {
         m_issues++;
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_MAJOR, "Consistency", "Level Database unavailable",
                         "Initialize LevelManager.");
        }

      if(m_h4_session == NULL)
        {
         m_issues++;
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_MAJOR, "Consistency", "Session Database unavailable",
                         "Initialize H4 Session Engine.");
        }

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Data consistency | issues=%d", m_issues),
                       "DataConsistency");
      return (m_issues == 0);
     }
  };

#endif // GM_CDATA_CONSISTENCY_CHECKER_MQH
//+------------------------------------------------------------------+
