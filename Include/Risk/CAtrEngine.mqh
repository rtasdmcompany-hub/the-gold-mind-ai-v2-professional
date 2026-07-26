//+------------------------------------------------------------------+
//|                                                CAtrEngine.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CATR_ENGINE_MQH
#define GM_CATR_ENGINE_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "RiskConstants.mqh"
#include "../Logging/CLogger.mqh"

/// @file CAtrEngine.mqh
/// @brief Modular ATR(14) H4 engine — official TP distance source.
/// @details TP distance = ATR × GM_ATR_TP_MULTIPLIER (1.0). AI-ready modular unit.

class CGmAtrEngine
  {
private:
   CGmLogger *m_logger;
   string     m_symbol;
   int        m_handle;
   int        m_period;
   bool       m_initialized;

public:
                     CGmAtrEngine(void)
                       : m_logger(NULL),
                         m_symbol(""),
                         m_handle(INVALID_HANDLE),
                         m_period(GM_ATR_PERIOD),
                         m_initialized(false)
     {
     }

                    ~CGmAtrEngine(void) { Shutdown(); }

   bool Init(CGmLogger *logger, const string symbol, const int period = GM_ATR_PERIOD)
     {
      Shutdown();
      m_logger = logger;
      m_symbol = symbol;
      m_period = (period > 0) ? period : GM_ATR_PERIOD;
      m_handle = iATR(m_symbol, GM_ATR_TIMEFRAME, m_period);
      if(m_handle == INVALID_HANDLE)
        {
         if(m_logger != NULL)
            m_logger.Error(StringFormat("iATR create failed | err=%d", GetLastError()), "AtrEngine");
         return false;
        }
      m_initialized = true;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("ATR Engine ready | %s H4 period=%d | TP_mult=%.2f",
                                    m_symbol, m_period, GM_ATR_TP_MULTIPLIER),
                       "AtrEngine");
      return true;
     }

   void Shutdown(void)
     {
      if(m_handle != INVALID_HANDLE)
        {
         IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
        }
      m_initialized = false;
     }

   bool IsInitialized(void) const { return m_initialized; }

   /// @brief Reads live H4 ATR value (buffer 0, shift 0).
   bool GetAtr(double &atr_out)
     {
      atr_out = 0.0;
      if(!m_initialized || m_handle == INVALID_HANDLE)
         return false;

      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(m_handle, 0, 0, 1, buf) != 1)
        {
         if(m_logger != NULL)
            m_logger.Error(StringFormat("ATR CopyBuffer failed | err=%d", GetLastError()), "AtrEngine");
         return false;
        }
      atr_out = buf[0];
      if(atr_out <= 0.0)
        {
         if(m_logger != NULL)
            m_logger.Warning("ATR value <= 0", "AtrEngine");
         return false;
        }
      return true;
     }

   /// @brief Official Gold Mind TP distance = ATR × 1.0
   bool GetTakeProfitDistance(double &tp_dist)
     {
      double atr = 0.0;
      if(!GetAtr(atr))
         return false;
      tp_dist = atr * GM_ATR_TP_MULTIPLIER;
      if(m_logger != NULL)
         m_logger.Info(StringFormat("ATR=%.5f | TP_dist=%.5f (×%.2f)",
                                    atr, tp_dist, GM_ATR_TP_MULTIPLIER),
                       "AtrEngine");
      return (tp_dist > 0.0);
     }
  };

#endif // GM_CATR_ENGINE_MQH
//+------------------------------------------------------------------+
