//+------------------------------------------------------------------+
//|                              CEccStrategyTemplateManager.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Templates load ONLY when no AI-managed trades are active    |
//+------------------------------------------------------------------+
#ifndef GM_CECC_STRATEGY_TEMPLATE_MANAGER_MQH
#define GM_CECC_STRATEGY_TEMPLATE_MANAGER_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmConfigurationCenterResult.mqh"
#include "../Logging/CLogger.mqh"

class CGmEccStrategyTemplateManager
  {
private:
   CGmLogger            *m_logger;
   ENUM_GM_ECC_TEMPLATE  m_active;
   int                   m_version;
   string                m_name;
   bool                  m_validated;
   int                   m_active_gm_trades;

public:
                     CGmEccStrategyTemplateManager(void)
                       : m_logger(NULL),
                         m_active(GM_ECC_TMPL_GOLDMIND_DEFAULT),
                         m_version(1),
                         m_name("Gold Mind Default"),
                         m_validated(true),
                         m_active_gm_trades(0) {}

   void Init(CGmLogger *logger)
     {
      m_logger = logger;
      m_active = GM_ECC_TMPL_GOLDMIND_DEFAULT;
      m_version = 1;
      m_name = GmEccTemplateName(m_active);
      m_validated = true;
      m_active_gm_trades = 0;
     }

   void SetActiveGmTrades(const int n) { m_active_gm_trades = (n < 0 ? 0 : n); }

   ENUM_GM_ECC_TEMPLATE Active(void) const { return m_active; }
   int Version(void) const { return m_version; }
   string Name(void) const { return m_name; }
   bool IsLocked(void) const { return m_active_gm_trades > 0; }
   bool MayApply(void) const { return m_active_gm_trades <= 0; }

   bool ValidateTemplate(const ENUM_GM_ECC_TEMPLATE t)
     {
      m_validated = (t >= GM_ECC_TMPL_GOLDMIND_DEFAULT && t <= GM_ECC_TMPL_CUSTOM);
      if(m_logger != NULL)
        {
         if(m_validated)
            m_logger.Info("Template Validation OK | " + GmEccTemplateName(t), "ECC");
         else
            m_logger.Error("Template Validation FAILED", "ECC");
        }
      return m_validated;
     }

   bool ApplyTemplate(const ENUM_GM_ECC_TEMPLATE t)
     {
      if(!MayApply())
        {
         if(m_logger != NULL)
            m_logger.Warning(StringFormat(
               "Template Apply BLOCKED | %d AI-managed trade(s) active — wait for flat session",
               m_active_gm_trades), "ECC");
         return false;
        }
      if(!ValidateTemplate(t))
         return false;

      m_active = t;
      m_name = GmEccTemplateName(t);
      m_version++;
      if(m_logger != NULL)
         m_logger.Success("Template Imported | " + m_name + " v" + IntegerToString(m_version) +
                          " | Catalog only — Core params unchanged", "ECC");
      return true;
     }

   void ApplyToResult(SGmConfigurationCenterResult &out) const
     {
      out.current_template = m_active;
      out.template_name = m_name;
      out.template_version = m_version;
      out.active_gm_trades = m_active_gm_trades;
      out.template_locked = IsLocked();
      out.may_apply_template = MayApply();
      out.may_modify_live_params = false;
     }
  };

#endif // GM_CECC_STRATEGY_TEMPLATE_MANAGER_MQH
//+------------------------------------------------------------------+
