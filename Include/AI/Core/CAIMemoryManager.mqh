//+------------------------------------------------------------------+
//|                                          CAIMemoryManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_CAI_MEMORY_MANAGER_MQH
#define GM_CAI_MEMORY_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "Phase3AIConstants.mqh"
#include "SGmAIBusSnapshot.mqh"

class CGmAIMemoryManager
  {
private:
   SGmAIBusSnapshot m_ring[GM_AI_CORE_MEM_MAX];
   int              m_n;
   int              m_head;
   bool             m_ready;

public:
                     CGmAIMemoryManager(void) : m_n(0), m_head(0), m_ready(false) {}

   void Init(void)
     {
      m_n = 0;
      m_head = 0;
      for(int i = 0; i < GM_AI_CORE_MEM_MAX; i++)
         m_ring[i].Reset();
      m_ready = true;
     }

   bool IsReady(void) const { return m_ready; }
   int Count(void) const { return m_n; }

   void Push(const SGmAIBusSnapshot &s)
     {
      if(!m_ready)
         return;
      m_ring[m_head] = s;
      m_head = (m_head + 1) % GM_AI_CORE_MEM_MAX;
      if(m_n < GM_AI_CORE_MEM_MAX)
         m_n++;
     }

   bool GetRecent(const int age, SGmAIBusSnapshot &out) const
     {
      out.Reset();
      if(!m_ready || age < 0 || age >= m_n)
         return false;
      int idx = m_head - 1 - age;
      while(idx < 0)
         idx += GM_AI_CORE_MEM_MAX;
      out = m_ring[idx];
      return out.valid;
     }
  };

#endif // GM_CAI_MEMORY_MANAGER_MQH
//+------------------------------------------------------------------+
