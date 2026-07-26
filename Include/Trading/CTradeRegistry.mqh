//+------------------------------------------------------------------+
//|                                            CTradeRegistry.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CTRADE_REGISTRY_MQH
#define GM_CTRADE_REGISTRY_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "../Risk/RiskConstants.mqh"
#include "../Logging/CLogger.mqh"
#include "../Core/CFileManager.mqh"
#include "SGmTradeRecord.mqh"

/// @file CTradeRegistry.mqh
/// @brief Internal trade database — survives EA restart via file persistence.

class CGmTradeRegistry
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   long            m_magic;
   string          m_symbol;
   string          m_file_name;
   SGmTradeRecord  m_records[GM_REGISTRY_MAX_TRADES];
   int             m_count;
   bool            m_initialized;
   bool            m_dirty;

   int FindSlotByTradeId(const ulong trade_id) const
     {
      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
        {
         if(m_records[i].used && m_records[i].trade_id == trade_id)
            return i;
        }
      return -1;
     }

   int FindSlotByTicket(const ulong ticket) const
     {
      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
        {
         if(m_records[i].used && m_records[i].ticket == ticket)
            return i;
        }
      return -1;
     }

   int FindFreeSlot(void) const
     {
      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
        {
         if(!m_records[i].used)
            return i;
        }
      return -1;
     }

   string SerializeRecord(const SGmTradeRecord &r) const
     {
      // v2: + original_volume | profit_pips | be_done | partial_done | trailing_active
      return StringFormat("%I64u|%I64u|%I64u|%I64d|%s|%s|%d|%I64d|%I64d|%.5f|%.5f|%.5f|%.2f|%.2f|%.2f|%d|%d|%d|%d|%d|%.2f|%.2f|%d|%d|%d",
                          r.trade_id, r.ticket, r.order_ticket, r.magic,
                          r.symbol, r.level_tag, (int)r.direction,
                          (long)r.h4_cycle_id, (long)r.open_time,
                          r.entry_price, r.stop_loss, r.take_profit, r.volume,
                          r.current_profit, r.current_loss, r.trade_attempts,
                          (int)r.status, (int)r.stage, (int)r.lifecycle, r.ai_status,
                          r.original_volume, r.profit_pips,
                          (r.be_done ? 1 : 0),
                          (r.partial_done ? 1 : 0),
                          (r.trailing_active ? 1 : 0));
     }

   bool DeserializeRecord(const string line, SGmTradeRecord &r)
     {
      r.Reset();
      string p[];
      const int n = StringSplit(line, '|', p);
      if(n < 20)
         return false;
      r.trade_id = (ulong)StringToInteger(p[0]);
      r.ticket = (ulong)StringToInteger(p[1]);
      r.order_ticket = (ulong)StringToInteger(p[2]);
      r.magic = StringToInteger(p[3]);
      r.symbol = p[4];
      r.level_tag = p[5];
      r.direction = (ENUM_GM_LEVEL_SIDE)StringToInteger(p[6]);
      r.h4_cycle_id = (datetime)StringToInteger(p[7]);
      r.open_time = (datetime)StringToInteger(p[8]);
      r.entry_price = StringToDouble(p[9]);
      r.stop_loss = StringToDouble(p[10]);
      r.take_profit = StringToDouble(p[11]);
      r.volume = StringToDouble(p[12]);
      r.current_profit = StringToDouble(p[13]);
      r.current_loss = StringToDouble(p[14]);
      r.trade_attempts = (int)StringToInteger(p[15]);
      r.status = (ENUM_GM_TRADE_STATUS)StringToInteger(p[16]);
      r.stage = (ENUM_GM_TRADE_STAGE)StringToInteger(p[17]);
      r.lifecycle = (ENUM_GM_LIFECYCLE)StringToInteger(p[18]);
      r.ai_status = (int)StringToInteger(p[19]);
      if(n >= 25)
        {
         r.original_volume = StringToDouble(p[20]);
         r.profit_pips = StringToDouble(p[21]);
         r.be_done = (StringToInteger(p[22]) != 0);
         r.partial_done = (StringToInteger(p[23]) != 0);
         r.trailing_active = (StringToInteger(p[24]) != 0);
        }
      else
        {
         r.original_volume = r.volume;
        }
      r.used = (r.trade_id > 0);
      return r.used;
     }

public:
                     CGmTradeRegistry(void)
                       : m_logger(NULL),
                         m_files(NULL),
                         m_magic(0),
                         m_symbol(""),
                         m_file_name(""),
                         m_count(0),
                         m_initialized(false),
                         m_dirty(false)
     {
      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
         m_records[i].Reset();
     }

                    ~CGmTradeRegistry(void)
     {
      if(m_initialized)
         Save();
      m_logger = NULL;
      m_files = NULL;
     }

   bool Init(CGmLogger *logger, CGmFileManager *files, const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      m_magic = magic;
      m_symbol = symbol;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_file_name = StringFormat("%s%I64d_%s.csv", GM_REGISTRY_FILE_PREFIX, magic, sym);

      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
         m_records[i].Reset();
      m_count = 0;
      m_initialized = true;
      Load();

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Trade Registry ready | file=%s | loaded=%d",
                                    m_file_name, m_count),
                       "TradeRegistry");
      return true;
     }

   void Shutdown(void)
     {
      Flush();
      m_initialized = false;
     }

   int Count(void) const { return m_count; }

   /// @brief Upsert record. persist=true writes immediately; false defers to Flush().
   bool Upsert(const SGmTradeRecord &rec, const bool persist = true)
     {
      if(!m_initialized || !rec.used || rec.trade_id == 0)
         return false;

      int slot = FindSlotByTradeId(rec.trade_id);
      if(slot < 0)
         slot = FindFreeSlot();
      if(slot < 0)
        {
         if(m_logger != NULL)
            m_logger.Error("Trade Registry full", "TradeRegistry");
         return false;
        }

      const bool was_used = m_records[slot].used;
      m_records[slot] = rec;
      m_records[slot].used = true;
      if(!was_used)
         m_count++;
      m_dirty = true;
      if(persist)
         Save();
      return true;
     }

   /// @brief Persist deferred registry changes (Sprint 9 performance hardening).
   void Flush(void)
     {
      if(m_dirty)
         Save();
     }

   bool GetByTradeId(const ulong trade_id, SGmTradeRecord &out) const
     {
      const int slot = FindSlotByTradeId(trade_id);
      if(slot < 0)
         return false;
      out = m_records[slot];
      return true;
     }

   bool GetByTicket(const ulong ticket, SGmTradeRecord &out) const
     {
      const int slot = FindSlotByTicket(ticket);
      if(slot < 0)
         return false;
      out = m_records[slot];
      return true;
     }

   bool UpdateProfit(const ulong ticket, const double profit)
     {
      const int slot = FindSlotByTicket(ticket);
      if(slot < 0)
         return false;
      if(profit >= 0.0)
        {
         m_records[slot].current_profit = profit;
         m_records[slot].current_loss = 0.0;
        }
      else
        {
         m_records[slot].current_loss = -profit;
         m_records[slot].current_profit = 0.0;
        }
      return true;
     }

   bool MarkActive(const ulong trade_id, const ulong position_ticket,
                   const double entry, const double sl, const double tp,
                   const datetime open_time)
     {
      const int slot = FindSlotByTradeId(trade_id);
      if(slot < 0)
         return false;
      m_records[slot].ticket = position_ticket;
      m_records[slot].entry_price = entry;
      m_records[slot].stop_loss = sl;
      m_records[slot].take_profit = tp;
      m_records[slot].open_time = open_time;
      m_records[slot].status = GM_TRADE_STATUS_ACTIVE;
      m_records[slot].stage = GM_TRADE_STAGE_RUNNING;
      m_records[slot].lifecycle = GM_LIFE_OPEN;
      if(PositionSelectByTicket(position_ticket))
        {
         const double vol = PositionGetDouble(POSITION_VOLUME);
         m_records[slot].volume = vol;
         if(m_records[slot].original_volume <= 0.0)
            m_records[slot].original_volume = vol;
        }
      Save();
      return true;
     }

   /// @brief Indexed access over used records (0 .. Count()-1).
   bool GetAt(const int index, SGmTradeRecord &out) const
     {
      if(index < 0)
         return false;
      int seen = 0;
      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
        {
         if(!m_records[i].used)
            continue;
         if(seen == index)
           {
            out = m_records[i];
            return true;
           }
         seen++;
        }
      return false;
     }

   void Save(void)
     {
      if(!m_initialized || m_files == NULL)
         return;

      string payload = "#GM_TRADE_REGISTRY\r\n";
      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
        {
         if(!m_records[i].used)
            continue;
         if(m_records[i].status == GM_TRADE_STATUS_CLOSED ||
            m_records[i].status == GM_TRADE_STATUS_CANCELLED)
            continue; // keep file lean — closed rows optional later
         payload += SerializeRecord(m_records[i]) + "\r\n";
        }
      m_files.WriteText(m_file_name, payload);
      m_dirty = false;
     }

   void Load(void)
     {
      if(m_files == NULL || !m_files.Exists(m_file_name))
         return;

      string content = "";
      if(!m_files.ReadText(m_file_name, content))
         return;

      string lines[];
      const int n = StringSplit(content, '\n', lines);
      m_count = 0;
      for(int i = 0; i < n; i++)
        {
         string line = lines[i];
         StringTrimLeft(line);
         StringTrimRight(line);
         StringReplace(line, "\r", "");
         if(StringLen(line) == 0 || StringGetCharacter(line, 0) == '#')
            continue;

         SGmTradeRecord rec;
         if(!DeserializeRecord(line, rec))
            continue;
         if(rec.magic != m_magic)
            continue;

         const int slot = FindFreeSlot();
         if(slot < 0)
            break;
         m_records[slot] = rec;
         m_count++;
        }

      if(m_logger != NULL)
         m_logger.Info(StringFormat("Registry loaded | records=%d", m_count), "TradeRegistry");
     }

   /// @brief Refresh PnL for active positions; mark missing tickets closed.
   void SyncFromTerminal(void)
     {
      for(int i = 0; i < GM_REGISTRY_MAX_TRADES; i++)
        {
         if(!m_records[i].used || m_records[i].status != GM_TRADE_STATUS_ACTIVE)
            continue;
         if(m_records[i].ticket == 0)
            continue;

         if(!PositionSelectByTicket(m_records[i].ticket))
           {
            m_records[i].status = GM_TRADE_STATUS_CLOSED;
            m_records[i].lifecycle = GM_LIFE_CLOSED;
            m_records[i].stage = GM_TRADE_STAGE_CLOSED;
            continue;
           }

         const double profit = PositionGetDouble(POSITION_PROFIT)
                               + PositionGetDouble(POSITION_SWAP);
         if(profit >= 0.0)
           {
            m_records[i].current_profit = profit;
            m_records[i].current_loss = 0.0;
           }
         else
           {
            m_records[i].current_loss = -profit;
            m_records[i].current_profit = 0.0;
           }
        }
     }
  };

#endif // GM_CTRADE_REGISTRY_MQH
//+------------------------------------------------------------------+
