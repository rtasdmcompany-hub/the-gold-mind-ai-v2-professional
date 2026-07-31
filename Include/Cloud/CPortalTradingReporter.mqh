//+------------------------------------------------------------------+
//|                                     CPortalTradingReporter.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|  Optional portal sync — reports account/trades only.            |
//|  Does NOT place, modify, or close trades. Safe companion.        |
//+------------------------------------------------------------------+
#ifndef TGM_PORTAL_TRADING_REPORTER_MQH
#define TGM_PORTAL_TRADING_REPORTER_MQH

#property copyright "RTAS Digital Marketing Company | RTAS Group of Companies"

//--- Configure via EA inputs (see TheGoldMindAI_Professional.mq5 hooks).
//    MT5 → Tools → Options → Expert Advisors → Allow WebRequest for listed URL
//    must include the portal base URL (e.g. https://the-gold-mind-ai-v2-professional.vercel.app)

struct TgmPortalReporterConfig
  {
   bool     enabled;
   string   baseUrl;           // no trailing slash
   string   customerEmail;
   string   licenseKey;        // optional if token set
   string   validationToken;   // optional activation Bearer token
   string   deviceFingerprint; // optional with email
   string   notifySecret;      // optional TRADE_NOTIFY_SECRET
   int      syncIntervalSec;   // periodic heartbeat
   long     magicFilter;       // 0 = all symbols' positions for this account; else magic filter
  };

static TgmPortalReporterConfig g_tgmPortalCfg;
static datetime                g_tgmPortalLastSync = 0;
static bool                    g_tgmPortalReady = false;

string TgmPortalJsonEscape(const string s)
  {
   string out = s;
   StringReplace(out, "\\", "\\\\");
   StringReplace(out, "\"", "\\\"");
   StringReplace(out, "\n", "\\n");
   StringReplace(out, "\r", "\\r");
   return out;
  }

string TgmPortalIsoTime(const datetime t)
  {
   if(t <= 0)
      return "";
   MqlDateTime dt;
   TimeToStruct(t, dt);
   return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                       dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
  }

string TgmPortalSideFromType(const long posType)
  {
   if(posType == POSITION_TYPE_SELL)
      return "sell";
   return "buy";
  }

string TgmPortalSideFromDeal(const long dealType)
  {
   if(dealType == DEAL_TYPE_SELL || dealType == DEAL_TYPE_SELL_CANCELED)
      return "sell";
   return "buy";
  }

void TgmPortalReporterInit(const TgmPortalReporterConfig &cfg)
  {
   g_tgmPortalCfg = cfg;
   g_tgmPortalReady = cfg.enabled;
   g_tgmPortalLastSync = 0;
   if(g_tgmPortalReady)
      Print("TGM PortalReporter: enabled → ", cfg.baseUrl, " (reporting only, no trading calls)");
  }

void TgmPortalReporterShutdown(void)
  {
   g_tgmPortalReady = false;
  }

bool TgmPortalHttpPost(const string path, const string jsonBody, string &responseOut)
  {
   responseOut = "";
   if(!g_tgmPortalReady || g_tgmPortalCfg.baseUrl == "")
      return false;

   string url = g_tgmPortalCfg.baseUrl;
   if(StringLen(url) > 0 && StringGetCharacter(url, StringLen(url) - 1) == '/')
      url = StringSubstr(url, 0, StringLen(url) - 1);
   url += path;

   char post[];
   char result[];
   string headers = "Content-Type: application/json\r\n";
   if(g_tgmPortalCfg.validationToken != "")
      headers += "Authorization: Bearer " + g_tgmPortalCfg.validationToken + "\r\n";
   if(g_tgmPortalCfg.notifySecret != "")
      headers += "x-tgm-notify-secret: " + g_tgmPortalCfg.notifySecret + "\r\n";

   StringToCharArray(jsonBody, post, 0, WHOLE_ARRAY, CP_UTF8);
   int postLen = ArraySize(post);
   if(postLen > 0 && post[postLen - 1] == 0)
      ArrayResize(post, postLen - 1);

   string resultHeaders = "";
   ResetLastError();
   int code = WebRequest("POST", url, headers, 8000, post, result, resultHeaders);
   if(code == -1)
     {
      int err = GetLastError();
      PrintFormat("TGM PortalReporter: WebRequest failed err=%d url=%s (add URL to allowed WebRequest list)", err, url);
      return false;
     }
   responseOut = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   return (code >= 200 && code < 300);
  }

string TgmPortalBuildAuthJsonFields(void)
  {
   string parts = "\"email\":\"" + TgmPortalJsonEscape(g_tgmPortalCfg.customerEmail) + "\"";
   if(g_tgmPortalCfg.licenseKey != "")
      parts += ",\"licenseKey\":\"" + TgmPortalJsonEscape(g_tgmPortalCfg.licenseKey) + "\"";
   if(g_tgmPortalCfg.deviceFingerprint != "")
      parts += ",\"deviceFingerprint\":\"" + TgmPortalJsonEscape(g_tgmPortalCfg.deviceFingerprint) + "\"";
   if(g_tgmPortalCfg.validationToken != "" && g_tgmPortalCfg.licenseKey == "")
      parts += ",\"token\":\"" + TgmPortalJsonEscape(g_tgmPortalCfg.validationToken) + "\"";
   return parts;
  }

string TgmPortalBuildOpenPositionsJson(void)
  {
   string json = "[";
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(g_tgmPortalCfg.magicFilter != 0 &&
         PositionGetInteger(POSITION_MAGIC) != g_tgmPortalCfg.magicFilter)
         continue;

      if(n > 0)
         json += ",";
      string side = TgmPortalSideFromType(PositionGetInteger(POSITION_TYPE));
      json += "{";
      json += "\"ticket\":\"" + IntegerToString((long)ticket) + "\",";
      json += "\"symbol\":\"" + TgmPortalJsonEscape(PositionGetString(POSITION_SYMBOL)) + "\",";
      json += "\"type\":\"" + side + "\",";
      json += "\"side\":\"" + side + "\",";
      json += "\"volume\":" + DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + ",";
      json += "\"openTime\":\"" + TgmPortalIsoTime((datetime)PositionGetInteger(POSITION_TIME)) + "\",";
      json += "\"profit\":" + DoubleToString(PositionGetDouble(POSITION_PROFIT)
                                            + PositionGetDouble(POSITION_SWAP), 2) + ",";
      json += "\"status\":\"open\"";
      json += "}";
      n++;
      if(n >= 80)
         break;
     }
   json += "]";
   return json;
  }

string TgmPortalBuildRecentClosedJson(const int lookbackHours)
  {
   datetime to = TimeCurrent();
   datetime from = to - lookbackHours * 3600;
   if(!HistorySelect(from, to))
      return "[]";

   string json = "[";
   int n = 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;
      if(g_tgmPortalCfg.magicFilter != 0 &&
         HistoryDealGetInteger(deal, DEAL_MAGIC) != g_tgmPortalCfg.magicFilter)
         continue;

      ulong posId = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
      string ticketKey = (posId > 0) ? IntegerToString((long)posId) : IntegerToString((long)deal);
      string side = TgmPortalSideFromDeal(HistoryDealGetInteger(deal, DEAL_TYPE));
      double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                    + HistoryDealGetDouble(deal, DEAL_SWAP)
                    + HistoryDealGetDouble(deal, DEAL_COMMISSION);

      if(n > 0)
         json += ",";
      json += "{";
      json += "\"ticket\":\"" + ticketKey + "\",";
      json += "\"symbol\":\"" + TgmPortalJsonEscape(HistoryDealGetString(deal, DEAL_SYMBOL)) + "\",";
      json += "\"type\":\"" + side + "\",";
      json += "\"side\":\"" + side + "\",";
      json += "\"volume\":" + DoubleToString(HistoryDealGetDouble(deal, DEAL_VOLUME), 2) + ",";
      json += "\"closeTime\":\"" + TgmPortalIsoTime((datetime)HistoryDealGetInteger(deal, DEAL_TIME)) + "\",";
      json += "\"profit\":" + DoubleToString(profit, 2) + ",";
      json += "\"status\":\"closed\",";
      json += "\"comment\":\"" + TgmPortalJsonEscape(HistoryDealGetString(deal, DEAL_COMMENT)) + "\"";
      json += "}";
      n++;
      if(n >= 120)
         break;
     }
   json += "]";
   return json;
  }

bool TgmPortalReporterSyncNow(const bool force)
  {
   if(!g_tgmPortalReady || !g_tgmPortalCfg.enabled)
      return false;
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION))
      return false;

   datetime now = TimeCurrent();
   int interval = MathMax(30, g_tgmPortalCfg.syncIntervalSec);
   if(!force && g_tgmPortalLastSync > 0 && (now - g_tgmPortalLastSync) < interval)
      return false;

   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   string server = AccountInfoString(ACCOUNT_SERVER);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   string body = "{";
   body += TgmPortalBuildAuthJsonFields();
   body += ",\"notifyClosed\":false";
   body += ",\"account\":{";
   body += "\"accountNumber\":\"" + IntegerToString(login) + "\",";
   body += "\"balance\":" + DoubleToString(balance, 2) + ",";
   body += "\"equity\":" + DoubleToString(equity, 2) + ",";
   body += "\"currency\":\"" + TgmPortalJsonEscape(currency) + "\",";
   body += "\"serverName\":\"" + TgmPortalJsonEscape(server) + "\"";
   body += "}";
   body += ",\"openPositions\":" + TgmPortalBuildOpenPositionsJson();
   body += ",\"closedDeals\":" + TgmPortalBuildRecentClosedJson(72);
   body += "}";

   string resp;
   bool ok = TgmPortalHttpPost("/api/trading/sync", body, resp);
   if(ok)
     {
      g_tgmPortalLastSync = now;
      Print("TGM PortalReporter: sync ok");
     }
   return ok;
  }

void TgmPortalReporterOnTimer(void)
  {
   TgmPortalReporterSyncNow(false);
  }

// Call from OnTradeTransaction when DEAL_ADD — report close to notify endpoint + refresh sync.
void TgmPortalReporterOnDealAdd(const ulong dealTicket)
  {
   if(!g_tgmPortalReady || !g_tgmPortalCfg.enabled || dealTicket == 0)
      return;
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION))
      return;
   if(!HistoryDealSelect(dealTicket))
      return;

   long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
     {
      // Still refresh open positions on entries
      TgmPortalReporterSyncNow(true);
      return;
     }
   if(g_tgmPortalCfg.magicFilter != 0 &&
      HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != g_tgmPortalCfg.magicFilter)
      return;

   ulong posId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   string ticketKey = (posId > 0) ? IntegerToString((long)posId) : IntegerToString((long)dealTicket);
   string side = TgmPortalSideFromDeal(HistoryDealGetInteger(dealTicket, DEAL_TYPE));
   double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                 + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                 + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
   long login = AccountInfoInteger(ACCOUNT_LOGIN);

   string body = "{";
   body += TgmPortalBuildAuthJsonFields();
   body += ",\"trade\":{";
   body += "\"ticket\":\"" + ticketKey + "\",";
   body += "\"symbol\":\"" + TgmPortalJsonEscape(HistoryDealGetString(dealTicket, DEAL_SYMBOL)) + "\",";
   body += "\"side\":\"" + side + "\",";
   body += "\"volume\":" + DoubleToString(HistoryDealGetDouble(dealTicket, DEAL_VOLUME), 2) + ",";
   body += "\"profit\":" + DoubleToString(profit, 2) + ",";
   body += "\"closeTime\":\"" + TgmPortalIsoTime((datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME)) + "\",";
   body += "\"comment\":\"" + TgmPortalJsonEscape(HistoryDealGetString(dealTicket, DEAL_COMMENT)) + "\",";
   body += "\"accountLogin\":\"" + IntegerToString(login) + "\"";
   body += "}}";

   string resp;
   TgmPortalHttpPost("/api/notifications/trade-closed", body, resp);
   TgmPortalReporterSyncNow(true);
  }

#endif // TGM_PORTAL_TRADING_REPORTER_MQH
