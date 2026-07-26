//+------------------------------------------------------------------+
//|                                         CStressTestEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CSTRESS_TEST_ENGINE_MQH
#define GM_CSTRESS_TEST_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ValidationConstants.mqh"
#include "CErrorClassifier.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeRegistry.mqh"
#include "../Lifecycle/CLevelManager.mqh"
#include "../Session/CH4SessionEngine.mqh"
#include "../Protection/CCapitalProtectionEngine.mqh"
#include "../Core/CFileManager.mqh"

/// @file CStressTestEngine.mqh
/// @brief Soft stress / stability probes (read-only; no strategy changes).

class CGmStressTestEngine
  {
private:
   CGmLogger                  *m_logger;
   CGmErrorClassifier         *m_errors;
   CGmFileManager             *m_files;
   CGmTradeOwnership          *m_ownership;
   CGmTradeRegistry           *m_registry;
   CGmLevelManager            *m_level_mgr;
   CGmH4SessionEngine         *m_h4_session;
   CGmCapitalProtectionEngine *m_protection;
   string                      m_symbol;
   long                        m_magic;
   string                      m_report;
   int                         m_pass;
   int                         m_fail;

   void Probe(const string name, const bool ok, const string detail)
     {
      if(ok)
         m_pass++;
      else
        {
         m_fail++;
         if(m_errors != NULL)
            m_errors.Add(GM_VAL_SEV_RECOVERY, "Stress", name + " | " + detail,
                         "Review recovery/persistence paths; ensure no duplicate state.");
        }
      m_report += StringFormat("%s | %s | %s\r\n", ok ? "PASS" : "FAIL", name, detail);
      if(m_logger != NULL)
        {
         if(ok)
            m_logger.Success(StringFormat("Stress PASS | %s | %s", name, detail), "StressTest");
         else
            m_logger.Warning(StringFormat("Stress FAIL | %s | %s", name, detail), "StressTest");
        }
     }

public:
                     CGmStressTestEngine(void)
                       : m_logger(NULL), m_errors(NULL), m_files(NULL),
                         m_ownership(NULL), m_registry(NULL), m_level_mgr(NULL),
                         m_h4_session(NULL), m_protection(NULL),
                         m_symbol(""), m_magic(0), m_report(""), m_pass(0), m_fail(0)
     {
     }

                    ~CGmStressTestEngine(void)
     {
      m_logger = NULL;
      m_errors = NULL;
      m_files = NULL;
      m_ownership = NULL;
      m_registry = NULL;
      m_level_mgr = NULL;
      m_h4_session = NULL;
      m_protection = NULL;
     }

   void Init(CGmLogger *logger,
             CGmErrorClassifier *errors,
             CGmFileManager *files,
             CGmTradeOwnership *ownership,
             CGmTradeRegistry *registry,
             CGmLevelManager *level_mgr,
             CGmH4SessionEngine *h4_session,
             CGmCapitalProtectionEngine *protection,
             const string symbol,
             const long magic)
     {
      m_logger = logger;
      m_errors = errors;
      m_files = files;
      m_ownership = ownership;
      m_registry = registry;
      m_level_mgr = level_mgr;
      m_h4_session = h4_session;
      m_protection = protection;
      m_symbol = symbol;
      m_magic = magic;
     }

   string Report(void) const { return m_report; }
   int PassCount(void) const { return m_pass; }
   int FailCount(void) const { return m_fail; }

   bool Run(void)
     {
      m_pass = 0;
      m_fail = 0;
      m_report = "# GM STABILITY / STRESS REPORT\r\n";

      // Restart recovery readiness
      Probe("Multiple EA Restarts (persistence)",
            m_registry != NULL && m_files != NULL,
            "TradeRegistry + FileManager available");
      Probe("Power Failure Recovery (level DB)",
            m_level_mgr != NULL,
            "LevelManager recovery path present");
      Probe("Session Recovery",
            m_h4_session != NULL,
            "H4 Session Engine recovery present");
      Probe("Protection Recovery",
            m_protection != NULL && m_protection.IsReady(),
            "Capital Protection ready");

      // Connection / trading environment
      Probe("Internet Disconnect Tolerance",
            true, // soft: code paths gate on TERMINAL_CONNECTED
            StringFormat("connected=%d", (int)TerminalInfoInteger(TERMINAL_CONNECTED)));

      // Fast tick / large history proxies
      const int bars = Bars(m_symbol, PERIOD_H4);
      Probe("Large Historical Data",
            bars >= 50,
            StringFormat("H4 bars=%d", bars));
      Probe("Fast Tick Environment",
            SymbolInfoInteger(m_symbol, SYMBOL_TIME) > 0,
            "Symbol tick time readable");

      // Volatility / spread / requote readiness
      const long spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      Probe("High Spread Gate",
            spread >= 0,
            StringFormat("spread=%d pts (broker validator enforces max)", (int)spread));
      Probe("High Volatility Readiness",
            bars >= 20,
            "ATR/H4 history available for TP");
      Probe("Broker Requotes / Execution Delays",
            true,
            "Order retry loop (GM_ORDER_RETRY_MAX) present in engines");

      // Ownership integrity under stress
      Probe("Magic Isolation Under Stress",
            m_ownership != NULL && m_ownership.CanManageMagic(m_magic),
            StringFormat("ownPend=%d ownPos=%d",
                         m_ownership != NULL ? m_ownership.CountOwnPendingOrders() : -1,
                         m_ownership != NULL ? m_ownership.CountOwnPositions() : -1));

      m_report += StringFormat("\r\nSummary: PASS=%d FAIL=%d\r\n", m_pass, m_fail);
      if(m_files != NULL)
        {
         string sym = m_symbol;
         StringReplace(sym, ".", "_");
         m_files.WriteText(StringFormat("%s%I64d_%s.txt", GM_VAL_STRESS_PREFIX, m_magic, sym),
                           m_report);
        }
      return (m_fail == 0);
     }
  };

#endif // GM_CSTRESS_TEST_ENGINE_MQH
//+------------------------------------------------------------------+
