//+------------------------------------------------------------------+
//|                                         CMarketValidator.mqh |
//|  PHASE 14A — Market Validator (real session/spread/ATR/news) |
//|  Calendar REAL NEWS when available; PROXY MODE fail-open else |
//+------------------------------------------------------------------+
#ifndef GM_CMARKET_VALIDATOR_MQH
#define GM_CMARKET_VALIDATOR_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmP14Validation.mqh"

//--- Local Phase 14A market thresholds (MarketValidator only)
#define GM_P14A_SPREAD_ELEVATED_MULT   1.80   // vs broker typical SYMBOL_SPREAD
#define GM_P14A_SPREAD_ABNORMAL_MULT   3.00
#define GM_P14A_ATR_DEAD_MULT          0.35   // vs median = abnormally quiet
#define GM_P14A_NEWS_WINDOW_SEC        1800   // ±30 minutes
#define GM_P14A_CALENDAR_PROBE_DAYS    7

enum ENUM_GM_P14A_NEWS_SOURCE
  {
   GM_P14A_NEWS_REAL = 0,
   GM_P14A_NEWS_PROXY
  };

enum ENUM_GM_P14A_SESSION
  {
   GM_P14A_SESS_CLOSED = 0,
   GM_P14A_SESS_ASIA,
   GM_P14A_SESS_LONDON,
   GM_P14A_SESS_NY,
   GM_P14A_SESS_OVERLAP,   // London/NY overlap
   GM_P14A_SESS_OFFHOURS
  };

class CMarketValidator
  {
private:
   int  m_atr_handle;
   bool m_calendar_probed;
   bool m_calendar_available;

   string SessionName(const ENUM_GM_P14A_SESSION s) const
     {
      switch(s)
        {
         case GM_P14A_SESS_ASIA:     return "ASIA";
         case GM_P14A_SESS_LONDON:   return "LONDON";
         case GM_P14A_SESS_NY:       return "NY";
         case GM_P14A_SESS_OVERLAP:  return "LONDON_NY_OVERLAP";
         case GM_P14A_SESS_OFFHOURS: return "OFFHOURS";
         case GM_P14A_SESS_CLOSED:   return "CLOSED";
        }
      return "UNKNOWN";
     }

   double ReadAtr(void) const
     {
      if(m_atr_handle == INVALID_HANDLE)
         return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 0, 1, buf) != 1)
         return 0.0;
      return buf[0];
     }

   double MedianAtr(const int count) const
     {
      if(m_atr_handle == INVALID_HANDLE || count < 3)
         return 0.0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_atr_handle, 0, 0, count, buf) < count)
         return 0.0;
      double tmp[];
      ArrayResize(tmp, count);
      for(int i = 0; i < count; i++)
         tmp[i] = buf[i];
      ArraySort(tmp);
      return tmp[count / 2];
     }

   //--- Probe MT5 Economic Calendar once (cached). Fail → PROXY MODE.
   bool EnsureCalendarAvailability(void)
     {
      if(m_calendar_probed)
         return m_calendar_available;

      m_calendar_probed = true;
      m_calendar_available = false;

      ResetLastError();
      MqlCalendarValue values[];
      const datetime to = TimeCurrent();
      const datetime from = to - (datetime)(GM_P14A_CALENDAR_PROBE_DAYS * 86400);
      const int n = CalendarValueHistory(values, from, to, NULL, NULL);
      const int err = GetLastError();

      // n >= 0 means API responded (0 events still = REAL NEWS path available)
      if(n >= 0 && err == 0)
         m_calendar_available = true;
      else
         m_calendar_available = false;

      return m_calendar_available;
     }

   bool ScanCountryHighImpact(const string countryCode, const datetime from, const datetime to) const
     {
      MqlCalendarValue values[];
      ResetLastError();
      const int n = CalendarValueHistory(values, from, to, countryCode, NULL);
      if(n <= 0)
         return false;

      for(int i = 0; i < n; i++)
        {
         MqlCalendarEvent ev;
         if(!CalendarEventById(values[i].event_id, ev))
            continue;
         if(ev.importance == CALENDAR_IMPORTANCE_HIGH)
            return true;
        }
      return false;
     }

   //--- REAL NEWS: MT5 calendar high-impact US/EU in ±30m window.
   bool DetectRealHighImpactNews(string &detail) const
     {
      detail = "";
      const datetime now = TimeCurrent();
      const datetime from = now - GM_P14A_NEWS_WINDOW_SEC;
      const datetime to   = now + GM_P14A_NEWS_WINDOW_SEC;

      const bool us = ScanCountryHighImpact("US", from, to);
      const bool eu = ScanCountryHighImpact("EU", from, to);
      if(us || eu)
        {
         detail = StringFormat("HI-impact %s%s", (us ? "US" : ""), (eu ? (us ? "+EU" : "EU") : ""));
         return true;
        }
      detail = "calendar-clear";
      return false;
     }

   //--- PROXY MODE: heuristic risk windows only (never hard-block for missing calendar).
   bool DetectProxyNewsRisk(string &detail) const
     {
      detail = "";
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);

      // First Friday of month 12:00-15:00 UTC ≈ NFP window (soft risk)
      if(dt.day_of_week == 5 && dt.day <= 7 && dt.hour >= 12 && dt.hour <= 15)
        {
         detail = "proxy-NFP-window";
         return true;
        }

      // Mid-month Wednesdays 18:00-20:00 UTC ≈ FOMC-ish soft risk
      if(dt.day_of_week == 3 && dt.day >= 14 && dt.day <= 22 && dt.hour >= 18 && dt.hour <= 20)
        {
         detail = "proxy-FOMC-window";
         return true;
        }

      detail = "proxy-clear";
      return false;
     }

   bool IsMarketTradeAllowed(void) const
     {
      const long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
      if(tradeMode == SYMBOL_TRADE_MODE_DISABLED)
         return false;

      // Session quote check — if no quote session now, treat as closed
      datetime from = 0, to = 0;
      // day_of_week: 0=Sunday in MqlDateTime
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int dow = dt.day_of_week; // 0..6
      // SymbolInfoSessionQuote uses 0=Sunday .. 6=Saturday
      if(SymbolInfoSessionQuote(_Symbol, (ENUM_DAY_OF_WEEK)dow, 0, from, to))
        {
         // If broker returns a session, verify current time is inside any quote session
         const datetime dayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
         bool inSession = false;
         for(int s = 0; s < 8; s++)
           {
            datetime f = 0, t = 0;
            if(!SymbolInfoSessionQuote(_Symbol, (ENUM_DAY_OF_WEEK)dow, s, f, t))
               break;
            const datetime absFrom = dayStart + (f % 86400);
            datetime absTo = dayStart + (t % 86400);
            if(t < f) // crosses midnight
               absTo += 86400;
            if(TimeCurrent() >= absFrom && TimeCurrent() <= absTo)
              {
               inSession = true;
               break;
              }
           }
         // If at least one session index exists and none matched → closed
         datetime f0 = 0, t0 = 0;
         if(SymbolInfoSessionQuote(_Symbol, (ENUM_DAY_OF_WEEK)dow, 0, f0, t0))
            return inSession;
        }

      return true; // no session table → fall back to weekday logic
     }

   ENUM_GM_P14A_SESSION DetectSession(bool &weekendOrClosed, string &detail) const
     {
      weekendOrClosed = false;
      detail = "";

      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);

      // Weekend
      if(dt.day_of_week == 0 || dt.day_of_week == 6)
        {
         weekendOrClosed = true;
         detail = "weekend";
         return GM_P14A_SESS_CLOSED;
        }

      // Friday late / gold rollover soft-close (UTC)
      if(dt.day_of_week == 5 && dt.hour >= 21)
        {
         weekendOrClosed = true;
         detail = "friday-late-close";
         return GM_P14A_SESS_CLOSED;
        }

      // Broker trade mode / quote session
      if(!IsMarketTradeAllowed())
        {
         weekendOrClosed = true;
         detail = "broker-session-closed";
         return GM_P14A_SESS_CLOSED;
        }

      const int h = dt.hour;
      // UTC session map for XAU
      if(h >= 12 && h < 16)
        {
         detail = "london-ny-overlap";
         return GM_P14A_SESS_OVERLAP;
        }
      if(h >= 7 && h < 12)
        {
         detail = "london";
         return GM_P14A_SESS_LONDON;
        }
      if(h >= 16 && h < 21)
        {
         detail = "new-york";
         return GM_P14A_SESS_NY;
        }
      if(h >= 0 && h < 7)
        {
         detail = "asia";
         return GM_P14A_SESS_ASIA;
        }

      detail = "off-hours";
      return GM_P14A_SESS_OFFHOURS;
     }

   void EvaluateSpread(double &score, string &why) const
     {
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double spreadPts = 0.0;
      if(point > 0.0 && ask >= bid)
         spreadPts = (ask - bid) / point;

      const double typical = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      const double elevatedAt = MathMax(GM_P14_MAX_SPREAD_POINTS * 0.5,
                                        typical * GM_P14A_SPREAD_ELEVATED_MULT);
      const double abnormalAt = MathMax((double)GM_P14_MAX_SPREAD_POINTS,
                                        typical * GM_P14A_SPREAD_ABNORMAL_MULT);

      if(spreadPts <= 0.0)
        {
         score -= 8.0;
         why += " spread-unknown";
         return;
        }

      if(spreadPts >= abnormalAt || spreadPts > GM_P14_MAX_SPREAD_POINTS)
        {
         score -= 35.0;
         why += StringFormat(" ABNORMAL-SPREAD(%.0f)", spreadPts);
        }
      else if(spreadPts >= elevatedAt)
        {
         score -= 14.0;
         why += StringFormat(" elevated-spread(%.0f)", spreadPts);
        }
      else
        {
         score += 8.0;
         why += StringFormat(" spread-ok(%.0f)", spreadPts);
        }
     }

   void EvaluateVolatility(double &score, string &why) const
     {
      const double atr = ReadAtr();
      const double med = MedianAtr(14);

      if(atr <= 0.0)
        {
         score -= 10.0;
         why += " atr-missing";
         return;
        }

      if(med > 0.0 && atr > med * GM_P14_ATR_SPIKE_MULT)
        {
         score -= 22.0;
         why += " ABNORMAL-ATR-SPIKE";
        }
      else if(med > 0.0 && atr < med * GM_P14A_ATR_DEAD_MULT)
        {
         score -= 12.0;
         why += " abnormal-low-ATR";
        }
      else
        {
         score += 8.0;
         why += " atr-ok";
        }
     }

   void EvaluateSession(double &score, string &why) const
     {
      bool closed = false;
      string detail = "";
      const ENUM_GM_P14A_SESSION sess = DetectSession(closed, detail);
      why += " sess=" + SessionName(sess);

      if(closed || sess == GM_P14A_SESS_CLOSED)
        {
         score -= 40.0;
         why += "(" + detail + ")";
         return;
        }

      if(sess == GM_P14A_SESS_OVERLAP)
        {
         score += 10.0;
         why += "(prime)";
        }
      else if(sess == GM_P14A_SESS_LONDON || sess == GM_P14A_SESS_NY)
        {
         score += 8.0;
         why += "(active)";
        }
      else if(sess == GM_P14A_SESS_ASIA)
        {
         score += 3.0;
         why += "(quiet)";
        }
      else // off hours
        {
         score -= 8.0;
         why += "(thin)";
        }
     }

   void EvaluateNewsAndBias(const bool isBuy, double &score, string &why,
                            ENUM_GM_P14A_NEWS_SOURCE &source)
     {
      string newsDetail = "";
      bool highImpact = false;

      if(EnsureCalendarAvailability())
        {
         source = GM_P14A_NEWS_REAL;
         highImpact = DetectRealHighImpactNews(newsDetail);
         // Unavailable events inside REAL mode = clear — never block for empty calendar
        }
      else
        {
         source = GM_P14A_NEWS_PROXY;
         highImpact = DetectProxyNewsRisk(newsDetail);
         // PROXY: soft risk only — never treat missing calendar as a hard news block
        }

      const string srcTag = (source == GM_P14A_NEWS_REAL) ? "REAL NEWS" : "PROXY MODE";
      why += " [" + srcTag + "]";

      if(highImpact)
        {
         if(source == GM_P14A_NEWS_REAL)
           {
            score -= 25.0;
            why += " HIGH-IMPACT-NEWS:" + newsDetail;
           }
         else
           {
            // Soft penalty only in proxy — do not fail solely due to unavailable calendar
            score -= 10.0;
            why += " soft-news-risk:" + newsDetail;
           }
        }
      else
        {
         score += 5.0;
         why += " " + newsDetail;
        }

      // Directional bias proxy (kept for compatibility with prior MarketValidator scoring)
      double sum = 0.0;
      for(int i = 1; i <= 5; i++)
         sum += iClose(_Symbol, PERIOD_H4, i);
      const double avg = sum / 5.0;
      const double px = iClose(_Symbol, PERIOD_H4, 0);
      if(isBuy && px >= avg) { score += 4.0; why += " bias+"; }
      else if(!isBuy && px <= avg) { score += 4.0; why += " bias+"; }
      else if(isBuy && px < avg * 0.995) { score -= 4.0; why += " bias-"; }
      else if(!isBuy && px > avg * 1.005) { score -= 4.0; why += " bias-"; }
     }

public:
                     CMarketValidator(void)
                       : m_atr_handle(INVALID_HANDLE),
                         m_calendar_probed(false),
                         m_calendar_available(false)
     {
     }

   void SetAtrHandle(const int handle)
     {
      m_atr_handle = handle;
     }

   // Backward-compatible API used by CInstitutionalValidationEngine
   SGmP14ModuleResult Validate(const bool isBuy)
     {
      SGmP14ModuleResult r;
      r.Reset();

      double score = 70.0;
      string why = "Market:";
      ENUM_GM_P14A_NEWS_SOURCE newsSource = GM_P14A_NEWS_PROXY;

      EvaluateSpread(score, why);
      EvaluateVolatility(score, why);
      EvaluateSession(score, why);
      EvaluateNewsAndBias(isBuy, score, why, newsSource);

      if(score > 100.0) score = 100.0;
      if(score < 0.0) score = 0.0;

      r.confidence = score;
      // Never fail solely because news calendar was unavailable (PROXY MODE soft-only).
      // Closed market / abnormal spread+ATR can still fail the module gate.
      r.pass = (score >= 50.0);
      r.reason = why + StringFormat(" conf=%.0f", score);

      PrintFormat("TGM [P14A-MARKET]: %s | pass=%s conf=%.0f | %s",
                  (newsSource == GM_P14A_NEWS_REAL ? "REAL NEWS" : "PROXY MODE"),
                  (r.pass ? "Y" : "N"),
                  r.confidence,
                  r.reason);

      return r;
     }
  };

#endif // GM_CMARKET_VALIDATOR_MQH
//+------------------------------------------------------------------+
