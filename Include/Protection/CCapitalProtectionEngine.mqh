//+------------------------------------------------------------------+
//|                                  CCapitalProtectionEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CCAPITAL_PROTECTION_ENGINE_MQH
#define GM_CCAPITAL_PROTECTION_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "ProtectionConstants.mqh"
#include "SGmProtectionSettings.mqh"
#include "CEventLogger.mqh"
#include "CAccountMonitor.mqh"
#include "CDrawdownMonitor.mqh"
#include "CBrokerSafetyEngine.mqh"
#include "CCapitalRiskValidator.mqh"
#include "CTradeSafetyValidator.mqh"
#include "CSystemHealthEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Core/EnumsCore.mqh"
#include "../Risk/CRiskEngine.mqh"
#include "../Trading/CTradeOwnership.mqh"
#include "../Trading/CTradeRegistry.mqh"

/// @file CCapitalProtectionEngine.mqh
/// @brief Sprint 6 orchestrator — account safety, DD warn, risk gates, health.

class CGmCapitalProtectionEngine
  {
private:
   CGmEventLogger           m_events;
   CGmAccountMonitor        m_account;
   CGmDrawdownMonitor       m_drawdown;
   CGmBrokerSafetyEngine    m_broker_safety;
   CGmCapitalRiskValidator  m_risk_gate;
   CGmTradeSafetyValidator  m_trade_safety;
   CGmSystemHealthEngine    m_health;
   CGmFileManager          *m_files;
   CGmRiskEngine           *m_risk;
   string                   m_symbol;
   long                     m_magic;
   string                   m_file_name;
   SGmProtectionSettings    m_settings;
   bool                     m_ready;
   bool                     m_recovered;

   void SaveState(void)
     {
      if(m_files == NULL || !m_ready)
         return;
      const SGmDrawdownState dd = m_drawdown.State();
      const string payload = StringFormat(
         "#GM_PROTECTION_STATE\r\n"
         "day_start_balance=%.2f\r\n"
         "day_key=%d\r\n"
         "peak_equity=%.2f\r\n"
         "day_start_equity=%.2f\r\n"
         "week_start_equity=%.2f\r\n"
         "month_start_equity=%.2f\r\n"
         "max_dd_pct=%.4f\r\n"
         "day_key_dd=%d\r\n"
         "week_key=%d\r\n"
         "month_key=%d\r\n"
         "warn_dd=%d\r\n"
         "warn_daily=%d\r\n",
         m_account.DayStartBalance(),
         m_account.DayKeyValue(),
         dd.peak_equity,
         dd.day_start_equity,
         dd.week_start_equity,
         dd.month_start_equity,
         dd.max_dd_pct,
         dd.day_key,
         dd.week_key,
         dd.month_key,
         (dd.warn_dd ? 1 : 0),
         (dd.warn_daily ? 1 : 0));
      m_files.WriteText(m_file_name, payload);
     }

   double ReadKvDouble(const string line, const string key) const
     {
      if(StringFind(line, key + "=") != 0)
         return 0.0;
      return StringToDouble(StringSubstr(line, StringLen(key) + 1));
     }

   int ReadKvInt(const string line, const string key) const
     {
      if(StringFind(line, key + "=") != 0)
         return 0;
      return (int)StringToInteger(StringSubstr(line, StringLen(key) + 1));
     }

   void LoadState(void)
     {
      if(m_files == NULL || !m_files.Exists(m_file_name))
         return;

      string content = "";
      if(!m_files.ReadText(m_file_name, content))
         return;

      SGmDrawdownState dd;
      dd.Reset();
      double day_bal = 0.0;
      int day_key = 0;

      string lines[];
      const int n = StringSplit(content, '\n', lines);
      for(int i = 0; i < n; i++)
        {
         string line = lines[i];
         StringTrimLeft(line);
         StringTrimRight(line);
         StringReplace(line, "\r", "");
         if(StringLen(line) == 0 || StringGetCharacter(line, 0) == '#')
            continue;

         if(StringFind(line, "day_start_balance=") == 0)
            day_bal = ReadKvDouble(line, "day_start_balance");
         else if(StringFind(line, "day_key=") == 0 && StringFind(line, "day_key_dd=") < 0)
            day_key = ReadKvInt(line, "day_key");
         else if(StringFind(line, "peak_equity=") == 0)
            dd.peak_equity = ReadKvDouble(line, "peak_equity");
         else if(StringFind(line, "day_start_equity=") == 0)
            dd.day_start_equity = ReadKvDouble(line, "day_start_equity");
         else if(StringFind(line, "week_start_equity=") == 0)
            dd.week_start_equity = ReadKvDouble(line, "week_start_equity");
         else if(StringFind(line, "month_start_equity=") == 0)
            dd.month_start_equity = ReadKvDouble(line, "month_start_equity");
         else if(StringFind(line, "max_dd_pct=") == 0)
            dd.max_dd_pct = ReadKvDouble(line, "max_dd_pct");
         else if(StringFind(line, "day_key_dd=") == 0)
            dd.day_key = ReadKvInt(line, "day_key_dd");
         else if(StringFind(line, "week_key=") == 0)
            dd.week_key = ReadKvInt(line, "week_key");
         else if(StringFind(line, "month_key=") == 0)
            dd.month_key = ReadKvInt(line, "month_key");
         else if(StringFind(line, "warn_dd=") == 0)
            dd.warn_dd = (ReadKvInt(line, "warn_dd") != 0);
         else if(StringFind(line, "warn_daily=") == 0)
            dd.warn_daily = (ReadKvInt(line, "warn_daily") != 0);
        }

      dd.valid = (dd.peak_equity > 0.0 || dd.day_start_equity > 0.0);
      m_account.SeedDayStart(day_bal, day_key);
      if(dd.valid)
         m_drawdown.Seed(dd);

      m_recovered = true;
      m_events.Recovery("CapitalProtection",
                        StringFormat("State recovered | peakEq=%.2f maxDD=%.2f%% dayBal=%.2f",
                                     dd.peak_equity, dd.max_dd_pct, day_bal));
     }

public:
                     CGmCapitalProtectionEngine(void)
                       : m_files(NULL),
                         m_risk(NULL),
                         m_symbol(""),
                         m_magic(0),
                         m_file_name(""),
                         m_ready(false),
                         m_recovered(false)
     {
      m_settings.Defaults();
     }

                    ~CGmCapitalProtectionEngine(void)
     {
      if(m_ready)
         SaveState();
      m_files = NULL;
      m_risk = NULL;
      m_ready = false;
     }

   bool Init(CGmLogger *logger,
             CGmFileManager *files,
             CGmRiskEngine *risk,
             CGmTradeOwnership *ownership,
             CGmTradeRegistry *registry,
             const string symbol,
             const long magic,
             const SGmProtectionSettings &settings)
     {
      m_files = files;
      m_risk = risk;
      m_symbol = symbol;
      m_magic = magic;
      m_settings = settings;

      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file_name = StringFormat("%s%I64d_%s.state", GM_PROT_STATE_FILE_PREFIX, magic, sym);

      m_events.Init(logger, settings.enable_detailed_logs);
      m_account.Init(GetPointer(m_events));
      m_drawdown.Init(GetPointer(m_events),
                      settings.max_drawdown_warn_pct,
                      settings.max_daily_loss_warn_pct);
      m_broker_safety.Init(GetPointer(m_events), symbol, settings.max_spread_points);
      m_risk_gate.Init(GetPointer(m_events),
                       GetPointer(m_account),
                       GetPointer(m_broker_safety),
                       risk,
                       settings.enable_capital_protection);
      m_trade_safety.Init(GetPointer(m_events), ownership, registry, magic);
      m_health.Init(GetPointer(m_events), symbol);

      if(risk != NULL)
         risk.SetMaxSpreadPoints(settings.max_spread_points);

      m_ready = true;
      LoadState();
      Process(GM_APP_STATE_INITIALIZING);

      m_events.Account("CapitalProtection",
                       StringFormat("Capital Protection Engine ready | enabled=%s spread=%d ddWarn=%.1f%% dailyWarn=%.1f%%",
                                    settings.enable_capital_protection ? "Y" : "N",
                                    settings.max_spread_points,
                                    settings.max_drawdown_warn_pct,
                                    settings.max_daily_loss_warn_pct),
                       GM_LOG_SUCCESS);
      return true;
     }

   void Shutdown(void)
     {
      SaveState();
      m_ready = false;
     }

   void Recover(void)
     {
      if(!m_ready)
         return;
      if(!m_recovered)
         LoadState();
      m_account.Refresh();
      m_broker_safety.Refresh();
      m_events.Recovery("CapitalProtection",
                       "Recovery complete | account + drawdown + broker + health");
     }

   void Process(const ENUM_GM_APP_STATE app_state)
     {
      if(!m_ready)
         return;
      const ulong t0 = GetMicrosecondCount();
      m_account.Refresh();
      m_drawdown.Update(m_account.Copy());
      m_broker_safety.Refresh();
      m_health.Refresh(app_state);
      m_health.RecordExecution(GetMicrosecondCount() - t0);

      // Persist periodically via process (lightweight)
      static datetime s_last_save = 0;
      if(TimeCurrent() - s_last_save >= 60)
        {
         SaveState();
         s_last_save = TimeCurrent();
        }
     }

   /// @brief Gate for new pending placement. DD warnings do NOT block (Sprint 6).
   bool CanPlaceNewOrders(void)
     {
      if(!m_ready)
         return true;
      if(!m_settings.enable_capital_protection)
         return true;
      return m_risk_gate.CanPlaceNewPending(m_symbol);
     }

   string LastRiskReason(void) const { return m_risk_gate.LastReason(); }

   bool CanManageTrade(const ulong ticket, const ulong trade_id = 0)
     {
      return m_trade_safety.CanManageTrade(ticket, trade_id);
     }

   CGmEventLogger *Events(void) { return GetPointer(m_events); }
   CGmAccountMonitor *Account(void) { return GetPointer(m_account); }
   CGmDrawdownMonitor *Drawdown(void) { return GetPointer(m_drawdown); }
   CGmBrokerSafetyEngine *BrokerSafety(void) { return GetPointer(m_broker_safety); }
   CGmTradeSafetyValidator *TradeSafety(void) { return GetPointer(m_trade_safety); }
   CGmSystemHealthEngine *Health(void) { return GetPointer(m_health); }
   SGmProtectionSettings Settings(void) const { return m_settings; }
   bool IsReady(void) const { return m_ready; }
  };

#endif // GM_CCAPITAL_PROTECTION_ENGINE_MQH
//+------------------------------------------------------------------+
