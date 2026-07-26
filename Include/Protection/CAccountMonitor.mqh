//+------------------------------------------------------------------+
//|                                          CAccountMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CACCOUNT_MONITOR_MQH
#define GM_CACCOUNT_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmAccountSnapshot.mqh"
#include "CEventLogger.mqh"

/// @file CAccountMonitor.mqh
/// @brief Continuously monitors account balance / equity / margin / daily PnL.

class CGmAccountMonitor
  {
private:
   CGmEventLogger    *m_events;
   SGmAccountSnapshot m_snap;
   double             m_day_start_balance;
   int                m_day_key;
   bool               m_ready;

   int DayKey(const datetime t) const
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      return dt.year * 10000 + dt.mon * 100 + dt.day;
     }

   void RollDayIfNeeded(const datetime now, const double balance)
     {
      const int key = DayKey(now);
      if(m_day_key != key)
        {
         m_day_key = key;
         m_day_start_balance = balance;
         if(m_events != NULL)
            m_events.Account("AccountMonitor",
                             StringFormat("New trading day | startBalance=%.2f", balance));
        }
     }

public:
                     CGmAccountMonitor(void)
                       : m_events(NULL),
                         m_day_start_balance(0.0),
                         m_day_key(0),
                         m_ready(false)
     {
      m_snap.Reset();
     }

                    ~CGmAccountMonitor(void) { m_events = NULL; }

   void Init(CGmEventLogger *events)
     {
      m_events = events;
      m_snap.Reset();
      const double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      m_day_start_balance = bal;
      m_day_key = DayKey(TimeCurrent());
      m_ready = true;
      Refresh();
      if(m_events != NULL)
         m_events.Account("AccountMonitor", "Account Protection Monitor ready");
     }

   void SeedDayStart(const double balance, const int day_key)
     {
      if(balance > 0.0)
         m_day_start_balance = balance;
      if(day_key > 0)
         m_day_key = day_key;
     }

   double DayStartBalance(void) const { return m_day_start_balance; }
   int    DayKeyValue(void) const { return m_day_key; }

   SGmAccountSnapshot Copy(void) const { return m_snap; }

   void Refresh(void)
     {
      if(!m_ready)
         return;

      const datetime now = TimeCurrent();
      const double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      const double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      RollDayIfNeeded(now, balance);

      m_snap.stamped_at = now;
      m_snap.balance = balance;
      m_snap.equity = equity;
      m_snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      m_snap.margin = AccountInfoDouble(ACCOUNT_MARGIN);
      m_snap.margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      m_snap.floating_pnl = equity - balance;
      if(m_snap.floating_pnl >= 0.0)
        {
         m_snap.floating_profit = m_snap.floating_pnl;
         m_snap.floating_loss = 0.0;
        }
      else
        {
         m_snap.floating_profit = 0.0;
         m_snap.floating_loss = -m_snap.floating_pnl;
        }

      m_snap.daily_pnl = equity - m_day_start_balance;
      if(m_snap.daily_pnl >= 0.0)
        {
         m_snap.daily_profit = m_snap.daily_pnl;
         m_snap.daily_loss = 0.0;
        }
      else
        {
         m_snap.daily_profit = 0.0;
         m_snap.daily_loss = -m_snap.daily_pnl;
        }
      m_snap.valid = true;

      if(m_events != NULL && m_events.Detailed())
         m_events.Account("AccountMonitor",
                          StringFormat("Bal=%.2f Eq=%.2f Free=%.2f ML=%.1f Float=%.2f DayPnL=%.2f",
                                       m_snap.balance, m_snap.equity, m_snap.free_margin,
                                       m_snap.margin_level, m_snap.floating_pnl, m_snap.daily_pnl),
                          GM_LOG_DEBUG);
     }
  };

#endif // GM_CACCOUNT_MONITOR_MQH
//+------------------------------------------------------------------+
