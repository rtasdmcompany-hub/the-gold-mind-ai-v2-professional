//+------------------------------------------------------------------+
//|                                               Version.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Copyright 2026, RTAS Group of Companies                     |
//+------------------------------------------------------------------+
#ifndef GM_VERSION_MQH
#define GM_VERSION_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

/// @file Version.mqh
/// @brief Central product identity, ownership, and version constants.
/// @details All version-facing surfaces (logs, reports, UI) must read from here.

//--- Product
#define GM_PRODUCT_NAME           "THE GOLD MIND AI PROFESSIONAL"
#define GM_PRODUCT_SHORT          "GoldMindAI"
#define GM_PRODUCT_CODE           "THE_GOLD_MIND_AI"

//--- Ownership
#define GM_OWNER_GROUP            "RTAS Group of Companies"
#define GM_OWNER_DIVISION         "RTAS Digital Marketing Company"
#define GM_OWNER_DEVELOPMENT      "RTAS Softwear"
#define GM_PRODUCT_COMPANY        GM_OWNER_GROUP
#define GM_PRODUCT_PROPRIETARY    "Proprietary enterprise trading system – All rights reserved"

//--- Version
#define GM_VERSION_MAJOR          2
#define GM_VERSION_MINOR          0
#define GM_VERSION_PATCH          0
#define GM_VERSION_BUILD          21060
#define GM_VERSION_STRING         "2.0.0"
#define GM_SPRINT_LABEL           "Phase 7 / Sprint 10 – Trading Ecosystem Certification, Hardening & Closure"

/// @brief Builds a human-readable version banner string.
string GmVersionBanner(void)
  {
   return StringFormat("%s v%s (build %d) | %s | %s",
                       GM_PRODUCT_NAME,
                       GM_VERSION_STRING,
                       GM_VERSION_BUILD,
                       GM_OWNER_GROUP,
                       GM_SPRINT_LABEL);
  }

/// @brief Builds an ownership banner for startup logs.
string GmOwnershipBanner(void)
  {
   return StringFormat("%s | Owner: %s | Division: %s | Dev: %s",
                       GM_PRODUCT_NAME,
                       GM_OWNER_GROUP,
                       GM_OWNER_DIVISION,
                       GM_OWNER_DEVELOPMENT);
  }

#endif // GM_VERSION_MQH
//+------------------------------------------------------------------+
