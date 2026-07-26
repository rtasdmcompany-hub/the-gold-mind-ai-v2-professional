//+------------------------------------------------------------------+
//|                                              CLevelDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CLEVEL_DATABASE_MQH
#define GM_CLEVEL_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmLevelRecord.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

/// @file CLevelDatabase.mqh
/// @brief Persistent level state database (survives EA restart).

class CGmLevelDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   long            m_magic;
   string          m_symbol;
   string          m_file_name;
   SGmLevelRecord  m_levels[GM_LEVEL_DB_MAX];
   ulong           m_next_level_id;
   bool            m_initialized;

   int IndexOfTag(const ENUM_GM_LEVEL_TAG tag) const { return (int)tag; }

   string Serialize(const SGmLevelRecord &r) const
     {
      return StringFormat("%I64u|%I64u|%I64u|%I64u|%I64d|%s|%s|%d|%d|%I64d|%.5f|%d|%d|%I64d|%I64d|%.2f|%.2f|%d",
                          r.level_id, r.trade_id, r.order_ticket, r.position_ticket, r.magic,
                          r.symbol, r.level_tag, (int)r.tag, (int)r.direction,
                          (long)r.h4_cycle_id, r.entry_price, r.attempt, (int)r.state,
                          (long)r.open_time, (long)r.close_time, r.profit, r.loss,
                          r.active_for_cycle ? 1 : 0);
     }

   bool Deserialize(const string line, SGmLevelRecord &r)
     {
      r.Reset();
      string p[];
      if(StringSplit(line, '|', p) < 18)
         return false;
      r.level_id = (ulong)StringToInteger(p[0]);
      r.trade_id = (ulong)StringToInteger(p[1]);
      r.order_ticket = (ulong)StringToInteger(p[2]);
      r.position_ticket = (ulong)StringToInteger(p[3]);
      r.magic = StringToInteger(p[4]);
      r.symbol = p[5];
      r.level_tag = p[6];
      r.tag = (ENUM_GM_LEVEL_TAG)StringToInteger(p[7]);
      r.direction = (ENUM_GM_LEVEL_SIDE)StringToInteger(p[8]);
      r.h4_cycle_id = (datetime)StringToInteger(p[9]);
      r.entry_price = StringToDouble(p[10]);
      r.attempt = (int)StringToInteger(p[11]);
      r.state = (ENUM_GM_LEVEL_STATE)StringToInteger(p[12]);
      r.open_time = (datetime)StringToInteger(p[13]);
      r.close_time = (datetime)StringToInteger(p[14]);
      r.profit = StringToDouble(p[15]);
      r.loss = StringToDouble(p[16]);
      r.active_for_cycle = (StringToInteger(p[17]) != 0);
      r.used = (r.level_id > 0);
      return r.used;
     }

public:
                     CGmLevelDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_magic(0), m_symbol(""),
                         m_file_name(""), m_next_level_id(1), m_initialized(false)
     {
      for(int i = 0; i < GM_LEVEL_DB_MAX; i++)
         m_levels[i].Reset();
     }

                    ~CGmLevelDatabase(void)
     {
      if(m_initialized) Save();
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
      m_file_name = StringFormat("%s%I64d_%s.csv", GM_LEVEL_DB_FILE_PREFIX, magic, sym);
      m_initialized = true;
      Load();
      if(m_logger != NULL)
         m_logger.Info(StringFormat("Level Database ready | nextLID=%I64u", m_next_level_id),
                       "LevelDatabase");
      return true;
     }

   void Shutdown(void) { Save(); m_initialized = false; }

   ulong AllocateLevelId(void) { return m_next_level_id++; }

   bool GetByTag(const ENUM_GM_LEVEL_TAG tag, SGmLevelRecord &out) const
     {
      const int idx = IndexOfTag(tag);
      if(idx < 0 || idx >= GM_LEVEL_DB_MAX || !m_levels[idx].used)
         return false;
      out = m_levels[idx];
      return true;
     }

   bool GetByLevelId(const ulong level_id, SGmLevelRecord &out) const
     {
      for(int i = 0; i < GM_LEVEL_DB_MAX; i++)
        {
         if(m_levels[i].used && m_levels[i].level_id == level_id)
           {
            out = m_levels[i];
            return true;
           }
        }
      return false;
     }

   bool GetByTradeId(const ulong trade_id, SGmLevelRecord &out) const
     {
      for(int i = 0; i < GM_LEVEL_DB_MAX; i++)
        {
         if(m_levels[i].used && m_levels[i].trade_id == trade_id)
           {
            out = m_levels[i];
            return true;
           }
        }
      return false;
     }

   bool GetByPositionTicket(const ulong ticket, SGmLevelRecord &out) const
     {
      for(int i = 0; i < GM_LEVEL_DB_MAX; i++)
        {
         if(m_levels[i].used && m_levels[i].position_ticket == ticket)
           {
            out = m_levels[i];
            return true;
           }
        }
      return false;
     }

   bool Upsert(const SGmLevelRecord &rec)
     {
      const int idx = IndexOfTag(rec.tag);
      if(idx < 0 || idx >= GM_LEVEL_DB_MAX)
         return false;
      m_levels[idx] = rec;
      m_levels[idx].used = true;
      if(rec.level_id >= m_next_level_id)
         m_next_level_id = rec.level_id + 1;
      Save();
      return true;
     }

   void ExpireAll(void)
     {
      for(int i = 0; i < GM_LEVEL_DB_MAX; i++)
        {
         if(!m_levels[i].used)
            continue;
         m_levels[i].state = GM_LVL_EXPIRED;
         m_levels[i].active_for_cycle = false;
        }
      Save();
     }

   void ClearSlots(void)
     {
      for(int i = 0; i < GM_LEVEL_DB_MAX; i++)
         m_levels[i].Reset();
      Save();
     }

   void Save(void)
     {
      if(!m_initialized || m_files == NULL)
         return;
      string payload = StringFormat("#GM_LEVEL_DB|next=%I64u\r\n", m_next_level_id);
      for(int i = 0; i < GM_LEVEL_DB_MAX; i++)
        {
         if(!m_levels[i].used)
            continue;
         payload += Serialize(m_levels[i]) + "\r\n";
        }
      m_files.WriteText(m_file_name, payload);
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
      for(int i = 0; i < n; i++)
        {
         string line = lines[i];
         StringTrimLeft(line);
         StringTrimRight(line);
         StringReplace(line, "\r", "");
         if(StringLen(line) == 0)
            continue;
         if(StringFind(line, "#GM_LEVEL_DB") == 0)
           {
            const int p = StringFind(line, "next=");
            if(p >= 0)
               m_next_level_id = (ulong)StringToInteger(StringSubstr(line, p + 5));
            continue;
           }
         if(StringGetCharacter(line, 0) == '#')
            continue;
         SGmLevelRecord rec;
         if(!Deserialize(line, rec) || rec.magic != m_magic)
            continue;
         const int idx = IndexOfTag(rec.tag);
         if(idx >= 0 && idx < GM_LEVEL_DB_MAX)
           {
            m_levels[idx] = rec;
            if(rec.level_id >= m_next_level_id)
               m_next_level_id = rec.level_id + 1;
           }
        }
     }
  };

#endif // GM_CLEVEL_DATABASE_MQH
//+------------------------------------------------------------------+
