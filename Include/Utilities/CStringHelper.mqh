//+------------------------------------------------------------------+
//|                                       CStringHelper.mqh          |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//+------------------------------------------------------------------+
#ifndef GM_CSTRING_HELPER_MQH
#define GM_CSTRING_HELPER_MQH
#property copyright "Copyright 2026, RTAS Softwear"
#property link      "https://rtas.softwear"

/// @file CStringHelper.mqh
/// @brief Lightweight string utilities shared across modules.

class CGmStringHelper
  {
public:
   /// @brief Returns true when value is null-length.
   static bool IsEmpty(const string value)
     {
      return (StringLen(value) == 0);
     }

   /// @brief Trims leading and trailing whitespace.
   static string Trim(const string value)
     {
      string result = value;
      StringTrimLeft(result);
      StringTrimRight(result);
      return result;
     }

   /// @brief Boolean to ON/OFF label.
   static string BoolToOnOff(const bool value)
     {
      return value ? "ON" : "OFF";
     }
  };

#endif // GM_CSTRING_HELPER_MQH
//+------------------------------------------------------------------+
