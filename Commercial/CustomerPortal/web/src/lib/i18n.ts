/**
 * Client-safe i18n helpers — re-exports types + cookie locale helpers.
 * Server modules under @/server/i18n must not be imported from client components.
 */
export type LocaleCode = "en" | "ur" | "ar" | "fr" | "de" | "es" | "tr" | string;

export const SUPPORTED_LOCALES: { code: LocaleCode; label: string; dir: "ltr" | "rtl" }[] = [
  { code: "en", label: "English", dir: "ltr" },
  { code: "ur", label: "اردو", dir: "rtl" },
  { code: "ar", label: "العربية", dir: "rtl" },
  { code: "fr", label: "Français", dir: "ltr" },
  { code: "de", label: "Deutsch", dir: "ltr" },
  { code: "es", label: "Español", dir: "ltr" },
  { code: "tr", label: "Türkçe", dir: "ltr" },
];

export const LOCALE_COOKIE = "gm_locale";

export function localeDirection(code: LocaleCode): "ltr" | "rtl" {
  return SUPPORTED_LOCALES.find((l) => l.code === code)?.dir || "ltr";
}
