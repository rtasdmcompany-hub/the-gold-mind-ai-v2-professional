//+------------------------------------------------------------------+
//|                                    CConversationDatabase.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CCONVERSATION_DATABASE_MQH
#define GM_CCONVERSATION_DATABASE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConversationResult.mqh"
#include "../../Core/CFileManager.mqh"
#include "../../Logging/CLogger.mqh"

class CGmConversationDatabase
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_rows[GM_CHAT_HIST_MAX];
   int             m_n;
   ulong           m_last_persist_ms;
   bool            m_ready;

   void WriteTable(const string table, const string body)
     {
      if(m_files == NULL) return;
      m_files.WriteText(m_pfx + table + ".txt", body);
     }

public:
                     CGmConversationDatabase(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_n(0),
                         m_last_persist_ms(0), m_ready(false) {}

   bool Init(CGmLogger *logger, CGmFileManager *files,
             const long magic, const string symbol)
     {
      m_logger = logger;
      m_files = files;
      string sym = symbol;
      StringReplace(sym, ".", "_");
      m_pfx = StringFormat("%s%I64d_%s_", GM_CHAT_DB_PREFIX, magic, sym);
      m_n = 0;
      m_ready = true;
      if(m_logger != NULL)
         m_logger.Info("Conversation Database Ready | " + m_pfx, "AIChat");
      return true;
     }

   void Shutdown(void)
     {
      Persist();
      m_ready = false;
     }

   string QueryInboxPath(void) const { return m_pfx + "query_inbox.txt"; }

   string TryReadInbox(void)
     {
      if(!m_ready || m_files == NULL)
         return "";
      string body = "";
      if(!m_files.ReadText(QueryInboxPath(), body))
         return "";
      StringTrimLeft(body);
      StringTrimRight(body);
      return body;
     }

   void Persist(void)
     {
      if(!m_ready || m_files == NULL) return;
      string body = "=== ai_conversations index ===\r\n";
      for(int i = 0; i < m_n; i++)
         body += m_rows[i] + "\r\n";
      m_files.WriteText(m_pfx + "ai_conversations.txt", body);
     }

   void Record(const SGmConversationResult &r)
     {
      if(!m_ready || !r.valid)
         return;

      const string ts = TimeToString(r.stamped_at, TIME_DATE | TIME_SECONDS);
      const string head = StringFormat("Timestamp=%s | SessionID=%I64u | Intent=%s | Security=%s\r\n",
                                       ts, r.session_id, GmChatIntentName(r.intent),
                                       GmChatSecName(r.security_status));

      WriteTable("ai_messages",
                 "=== ai_messages ===\r\n" + head +
                 "Q: " + r.user_query + "\r\nA: " + r.ai_response + "\r\n");
      WriteTable("ai_queries",
                 "=== ai_queries ===\r\n" + head + r.user_query + "\r\n");
      WriteTable("ai_responses",
                 "=== ai_responses ===\r\n" + head + r.ai_response + "\r\n");
      WriteTable("ai_context_history",
                 "=== ai_context_history ===\r\n" + head + r.context_summary + "\r\n");
      WriteTable("ai_command_logs",
                 "=== ai_command_logs ===\r\n" + head +
                 StringFormat("MayExecute=%s MayModifyOrders=%s MayModifyRisk=%s\r\n",
                              r.may_execute ? "true" : "false",
                              r.may_modify_orders ? "true" : "false",
                              r.may_modify_risk ? "true" : "false"));

      const string line = StringFormat("%s | %s | %s | %s",
                                       ts, GmChatIntentName(r.intent),
                                       GmChatSecName(r.security_status),
                                       r.short_response);
      if(m_n < GM_CHAT_HIST_MAX)
         m_rows[m_n++] = line;
      else
        {
         for(int i = 1; i < GM_CHAT_HIST_MAX; i++)
            m_rows[i - 1] = m_rows[i];
         m_rows[GM_CHAT_HIST_MAX - 1] = line;
        }

      const ulong now = GetTickCount();
      if(m_last_persist_ms == 0 || (now - m_last_persist_ms) > 7000)
        {
         Persist();
         m_last_persist_ms = now;
         if(m_logger != NULL)
            m_logger.Info("Database Synchronization Completed | Conversation tables", "AIChat");
        }
     }
  };

#endif // GM_CCONVERSATION_DATABASE_MQH
//+------------------------------------------------------------------+
