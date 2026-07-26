//+------------------------------------------------------------------+
//|                                           IGmNewsProvider.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_IGM_NEWS_PROVIDER_MQH
#define GM_IGM_NEWS_PROVIDER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmNewsAnalysisResult.mqh"

/// @brief Provider interface for future calendar / API / RSS / broker feeds.
/// @note Concrete providers implement Fetch(); orchestrator never trades.
class CGmNewsProviderBase
  {
protected:
   bool   m_ready;
   string m_name;

public:
                     CGmNewsProviderBase(void) : m_ready(false), m_name("Base") {}
   virtual          ~CGmNewsProviderBase(void) {}

   virtual ENUM_GM_NEWS_PROVIDER Type(void) const { return GM_NEWS_PROVIDER_NONE; }
   virtual string Name(void) const { return m_name; }
   virtual bool IsReady(void) const { return m_ready; }

   virtual bool Init(void)
     {
      m_ready = true;
      return true;
     }

   /// @return number of events written into out[]
   virtual int Fetch(SGmNewsEvent &out[], const datetime from_t, const datetime to_t)
     {
      ArrayResize(out, 0);
      return 0;
     }
  };

#endif // GM_IGM_NEWS_PROVIDER_MQH
//+------------------------------------------------------------------+
