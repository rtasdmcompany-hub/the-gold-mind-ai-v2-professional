//+------------------------------------------------------------------+
//|                                          CEtjExportCenter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Export architecture only — PDF/Excel reserved               |
//+------------------------------------------------------------------+
#ifndef GM_CETJ_EXPORT_CENTER_MQH
#define GM_CETJ_EXPORT_CENTER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "TradeJournalConstants.mqh"
#include "SGmTradeJournalPlatformResult.mqh"
#include "CEtjJournalEngine.mqh"
#include "../Core/CFileManager.mqh"
#include "../Logging/CLogger.mqh"

class CGmEtjExportCenter
  {
private:
   CGmLogger      *m_logger;
   CGmFileManager *m_files;
   string          m_pfx;
   string          m_status;

public:
                     CGmEtjExportCenter(void)
                       : m_logger(NULL), m_files(NULL), m_pfx(""), m_status("Idle") {}

   void Init(CGmLogger *logger, CGmFileManager *files, const string prefix)
     {
      m_logger = logger;
      m_files = files;
      m_pfx = prefix;
      m_status = "Architecture Ready | CSV live | PDF/Excel/Investor = ARCH";
     }

   string Status(void) const { return m_status; }

   void ExportCsv(CGmEtjJournalEngine *journal, const SGmTradeJournalPlatformResult &r)
     {
      if(m_files == NULL || journal == NULL)
         return;

      string csv = "TradeID,Side,Status,OpenTime,CloseTime,Entry,Exit,Lots,PnL,Session,DurationSec\r\n";
      SGmEtjTradeRecord t;
      for(int i = 0; i < journal.Count(); i++)
        {
         if(!journal.GetAt(i, t))
            continue;
         csv += StringFormat("%I64u,%s,%s,%s,%s,%.5f,%.5f,%.2f,%.2f,%s,%d\r\n",
                             t.trade_id,
                             GmEtjSideName(t.side),
                             GmEtjStatusName(t.status),
                             TimeToString(t.open_time, TIME_DATE | TIME_SECONDS),
                             TimeToString(t.close_time, TIME_DATE | TIME_SECONDS),
                             t.entry_price, t.exit_price, t.lot_size, t.profit_loss,
                             t.market_session, t.duration_sec);
        }

      m_files.WriteText(m_pfx + "trade_history_export.csv", csv);
      m_files.WriteText(m_pfx + "performance_report.txt",
                        "=== PERFORMANCE REPORT ===\r\n" +
                        r.analytics_summary + "\r\n" +
                        StringFormat("WinRate=%.1f ProfitFactor=%.2f Exec=%.0f\r\n",
                                     r.win_rate, r.profit_factor, r.execution_score));

      // Architecture stubs
      m_files.WriteText(m_pfx + "export_pdf.arch.txt",
                        "PDF Reports — architecture reserved for future renderer\r\n");
      m_files.WriteText(m_pfx + "export_excel.arch.txt",
                        "Excel Reports — architecture reserved\r\n");
      m_files.WriteText(m_pfx + "export_investor.arch.txt",
                        "Investor Reports — architecture reserved\r\n");

      m_status = "CSV Exported | PDF/Excel/Investor ARCH";
      if(m_logger != NULL)
         m_logger.Info("Report Generated | " + m_status, "ETJ");
     }
  };

#endif // GM_CETJ_EXPORT_CENTER_MQH
//+------------------------------------------------------------------+
