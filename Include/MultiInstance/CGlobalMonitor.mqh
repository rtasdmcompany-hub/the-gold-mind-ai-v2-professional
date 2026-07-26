//+------------------------------------------------------------------+
//|                                            CGlobalMonitor.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CGLOBAL_MONITOR_MQH
#define GM_CGLOBAL_MONITOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmInstanceRecord.mqh"
#include "SGmGlobalMonitorSnapshot.mqh"
#include "../Logging/CLogger.mqh"

/// @file CGlobalMonitor.mqh
/// @brief READ-ONLY aggregation of instance heartbeats (FILE_COMMON).
/// @warning Never issues trading commands.

class CGmGlobalMonitor
  {
private:
   CGmLogger            *m_logger;
   SGmInstanceRecord     m_peers[GM_INSTANCE_MAX];
   int                   m_peer_count;
   SGmGlobalMonitorSnapshot m_snap;

   int FindPeer(const string instance_id) const
     {
      for(int i = 0; i < m_peer_count; i++)
        {
         if(m_peers[i].used && m_peers[i].instance_id == instance_id)
            return i;
        }
      return -1;
     }

   void UpsertPeer(const SGmInstanceRecord &rec)
     {
      int idx = FindPeer(rec.instance_id);
      if(idx < 0)
        {
         if(m_peer_count >= GM_INSTANCE_MAX)
            return;
         idx = m_peer_count++;
        }
      m_peers[idx] = rec;
      m_peers[idx].used = true;
      m_peers[idx].stale = ((TimeCurrent() - rec.heartbeat_at) > GM_INSTANCE_STALE_SEC);
     }

   bool ParseHeartbeatFile(const string fname)
     {
      const int h = FileOpen(fname, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
      if(h == INVALID_HANDLE)
         return false;
      string body = "";
      while(!FileIsEnding(h))
        {
         string line = FileReadString(h);
         if(StringLen(line) > 0)
            body += line + "\n";
        }
      FileClose(h);
      if(StringLen(body) < 8)
         return false;

      string lines[];
      const int n = StringSplit(body, '\n', lines);
      for(int i = 0; i < n; i++)
        {
         string line = lines[i];
         StringTrimLeft(line);
         StringTrimRight(line);
         if(StringLen(line) < 8 || StringGetCharacter(line, 0) == '#')
            continue;
         SGmInstanceRecord rec;
         if(!rec.Deserialize(line))
            continue;
         UpsertPeer(rec);
         return true;
        }
      return false;
     }

public:
                     CGmGlobalMonitor(void) : m_logger(NULL), m_peer_count(0)
     {
      m_snap.Reset();
     }

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_peer_count = 0;
      m_snap.Reset();
     }

   int PeerCount(void) const { return m_peer_count; }
   SGmGlobalMonitorSnapshot Snapshot(void) const { return m_snap; }

   bool GetPeer(const int index, SGmInstanceRecord &out) const
     {
      if(index < 0 || index >= m_peer_count || !m_peers[index].used)
         return false;
      out = m_peers[index];
      return true;
     }

   /// @brief Scan common folder for GM_INST_*.hb heartbeats.
   void Refresh(const SGmInstanceRecord &local)
     {
      const ulong t0 = GetMicrosecondCount();
      m_peer_count = 0;

      string fname = "";
      long handle = FileFindFirst(GM_INSTANCE_HB_PREFIX + "*.hb", fname, FILE_COMMON);
      if(handle != INVALID_HANDLE)
        {
         do
           {
            ParseHeartbeatFile(fname);
           }
         while(FileFindNext(handle, fname));
         FileFindClose(handle);
        }

      // Ensure local is present even if write lag
      UpsertPeer(local);

      m_snap.Reset();
      m_snap.local_instance_id = local.instance_id;
      m_snap.local_chart_id = local.chart_id;
      m_snap.local_symbol = local.symbol;
      m_snap.local_timeframe = local.timeframe;
      m_snap.local_health = local.health_score;
      m_snap.local_status = local.StatusName();

      string symbols[GM_INSTANCE_MAX];
      int sym_n = 0;
      double health_sum = 0.0;
      int health_n = 0;
      double risk_sum = 0.0;
      double dd_max = 0.0;

      for(int i = 0; i < m_peer_count; i++)
        {
         if(!m_peers[i].used)
            continue;
         m_peers[i].stale = ((TimeCurrent() - m_peers[i].heartbeat_at) > GM_INSTANCE_STALE_SEC);
         if(m_peers[i].stale || m_peers[i].status == GM_INST_CLOSED)
            continue;

         m_snap.total_instances++;
         m_snap.total_open_trades += m_peers[i].open_trades;
         m_snap.total_pending_orders += m_peers[i].pending_orders;
         m_snap.overall_floating_profit += m_peers[i].floating_profit;
         m_snap.overall_floating_loss += m_peers[i].floating_loss;
         m_snap.overall_equity += m_peers[i].equity;
         risk_sum += m_peers[i].risk_pct;
         if(m_peers[i].drawdown_pct > dd_max)
            dd_max = m_peers[i].drawdown_pct;
         health_sum += m_peers[i].health_score;
         health_n++;

         bool known = false;
         for(int s = 0; s < sym_n; s++)
           {
            if(symbols[s] == m_peers[i].symbol)
              {
               known = true;
               break;
              }
           }
         if(!known && sym_n < GM_INSTANCE_MAX)
            symbols[sym_n++] = m_peers[i].symbol;
        }

      m_snap.active_symbols = sym_n;
      m_snap.overall_risk_pct = (m_snap.total_instances > 0)
                                ? (risk_sum / (double)m_snap.total_instances) : 0.0;
      m_snap.overall_drawdown_pct = dd_max;
      m_snap.global_health = (health_n > 0) ? (health_sum / (double)health_n) : 0.0;
      m_snap.sync_us = GetMicrosecondCount() - t0;
      m_snap.stamped_at = TimeCurrent();
      m_snap.valid = true;

      if(m_logger != NULL)
         m_logger.Debug(StringFormat("Performance Statistics | instances=%d symbols=%d open=%d | %I64u us",
                                     m_snap.total_instances, m_snap.active_symbols,
                                     m_snap.total_open_trades, m_snap.sync_us),
                        "GlobalMonitor");
     }
  };

#endif // GM_CGLOBAL_MONITOR_MQH
//+------------------------------------------------------------------+
