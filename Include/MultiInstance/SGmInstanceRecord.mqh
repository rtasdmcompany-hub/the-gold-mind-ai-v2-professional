//+------------------------------------------------------------------+
//|                                        SGmInstanceRecord.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_SGM_INSTANCE_RECORD_MQH
#define GM_SGM_INSTANCE_RECORD_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "MultiInstanceConstants.mqh"

/// @file SGmInstanceRecord.mqh
/// @brief One EA instance heartbeat / registry row (READ-ONLY aggregation).

struct SGmInstanceRecord
  {
   string                  instance_id;
   long                    chart_id;
   string                  chart_name;
   long                    magic;
   string                  symbol;
   string                  timeframe;
   ulong                   session_id;
   datetime                start_time;
   datetime                heartbeat_at;
   ENUM_GM_INSTANCE_STATUS status;
   string                  ea_version;
   string                  dashboard_status;
   string                  trading_status;
   string                  analytics_status;
   string                  recovery_status;
   bool                    chart_active;
   bool                    trading_enabled;
   bool                    internet_ok;
   bool                    broker_connected;
   int                     open_trades;
   int                     pending_orders;
   double                  floating_profit;
   double                  floating_loss;
   double                  equity;
   double                  risk_pct;
   double                  drawdown_pct;
   double                  health_score;
   ulong                   memory_kb;
   double                  cpu_est;
   bool                    used;
   bool                    stale;

   void Reset(void)
     {
      instance_id = "";
      chart_id = 0;
      chart_name = "";
      magic = 0;
      symbol = "";
      timeframe = "";
      session_id = 0;
      start_time = 0;
      heartbeat_at = 0;
      status = GM_INST_STARTING;
      ea_version = "";
      dashboard_status = "—";
      trading_status = "—";
      analytics_status = "—";
      recovery_status = "—";
      chart_active = false;
      trading_enabled = false;
      internet_ok = false;
      broker_connected = false;
      open_trades = 0;
      pending_orders = 0;
      floating_profit = 0.0;
      floating_loss = 0.0;
      equity = 0.0;
      risk_pct = 0.0;
      drawdown_pct = 0.0;
      health_score = 0.0;
      memory_kb = 0;
      cpu_est = 0.0;
      used = false;
      stale = false;
     }

   string StatusName(void) const
     {
      switch(status)
        {
         case GM_INST_RUNNING: return "RUNNING";
         case GM_INST_PAUSED:  return "PAUSED";
         case GM_INST_ERROR:   return "ERROR";
         case GM_INST_CLOSED:  return "CLOSED";
         default:              return "STARTING";
        }
     }

   string Serialize(void) const
     {
      return StringFormat(
                "%s|%I64d|%s|%I64d|%s|%s|%I64u|%I64d|%I64d|%d|%s|%s|%s|%s|%s|%d|%d|%d|%d|"
                "%d|%d|%.2f|%.2f|%.2f|%.2f|%.2f|%.1f|%I64u|%.1f",
                instance_id, chart_id, chart_name, magic, symbol, timeframe, session_id,
                (long)start_time, (long)heartbeat_at, (int)status, ea_version,
                dashboard_status, trading_status, analytics_status, recovery_status,
                chart_active ? 1 : 0, trading_enabled ? 1 : 0,
                internet_ok ? 1 : 0, broker_connected ? 1 : 0,
                open_trades, pending_orders,
                floating_profit, floating_loss, equity, risk_pct, drawdown_pct,
                health_score, memory_kb, cpu_est);
     }

   bool Deserialize(const string line)
     {
      Reset();
      string p[];
      if(StringSplit(line, '|', p) < 29)
         return false;
      instance_id = p[0];
      chart_id = StringToInteger(p[1]);
      chart_name = p[2];
      magic = StringToInteger(p[3]);
      symbol = p[4];
      timeframe = p[5];
      session_id = (ulong)StringToInteger(p[6]);
      start_time = (datetime)StringToInteger(p[7]);
      heartbeat_at = (datetime)StringToInteger(p[8]);
      status = (ENUM_GM_INSTANCE_STATUS)StringToInteger(p[9]);
      ea_version = p[10];
      dashboard_status = p[11];
      trading_status = p[12];
      analytics_status = p[13];
      recovery_status = p[14];
      chart_active = (StringToInteger(p[15]) != 0);
      trading_enabled = (StringToInteger(p[16]) != 0);
      internet_ok = (StringToInteger(p[17]) != 0);
      broker_connected = (StringToInteger(p[18]) != 0);
      open_trades = (int)StringToInteger(p[19]);
      pending_orders = (int)StringToInteger(p[20]);
      floating_profit = StringToDouble(p[21]);
      floating_loss = StringToDouble(p[22]);
      equity = StringToDouble(p[23]);
      risk_pct = StringToDouble(p[24]);
      drawdown_pct = StringToDouble(p[25]);
      health_score = StringToDouble(p[26]);
      memory_kb = (ulong)StringToInteger(p[27]);
      cpu_est = StringToDouble(p[28]);
      used = (StringLen(instance_id) > 0);
      return used;
     }
  };

#endif // GM_SGM_INSTANCE_RECORD_MQH
//+------------------------------------------------------------------+
