/**
 * Mobile Companion shell — screens for account, licenses, support, notifications.
 * Intentionally contains ZERO trading UI or order entry.
 */
export const SCREENS = [
  "Login",
  "Dashboard",
  "Licenses",
  "Devices",
  "Notifications",
  "Support",
  "Settings",
] as const;

export function assertNoTradingSurface(): true {
  return true;
}
