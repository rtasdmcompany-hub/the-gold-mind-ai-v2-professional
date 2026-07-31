/**
 * Translation runtime — t(), pluralization, Intl formatting, fallback.
 * Brand tokens (`{productName}`, `{supportEmail}`, …) always resolve from `@/lib/brand`.
 */
import { brandTokens } from "@/lib/brand";
import type { LocaleCode, RegionalSettings } from "./types";
import { getLocalePack } from "./packs";

export const DEFAULT_REGIONAL: RegionalSettings = {
  language: "en",
  timezone: "UTC",
  dateFormat: "medium",
  currency: "USD",
  measurement: "metric",
  legalNoticeKey: "regional.legal.notice",
  supportContactKey: "regional.support.contact",
};

function interpolate(template: string, vars?: Record<string, string | number>): string {
  const merged: Record<string, string | number> = { ...brandTokens(), ...vars };
  return template.replace(/\{(\w+)\}/g, (_, k: string) =>
    merged[k] !== undefined ? String(merged[k]) : `{${k}}`
  );
}

/**
 * Resolve message with fallback chain: locale → fallback → en → key.
 */
export function t(
  key: string,
  locale: LocaleCode = "en",
  vars?: Record<string, string | number>
): string {
  const pack = getLocalePack(locale);
  const fallbackCode = pack.manifest.fallback || "en";
  const fb = getLocalePack(fallbackCode);
  const en = getLocalePack("en");
  const raw =
    pack.catalog[key] ??
    (fallbackCode !== locale ? fb.catalog[key] : undefined) ??
    en.catalog[key] ??
    key;
  return interpolate(raw, vars);
}

/** Pluralization via ICU-lite: key_one / key_other (and optional key_zero). */
export function tp(
  baseKey: string,
  count: number,
  locale: LocaleCode = "en",
  vars?: Record<string, string | number>
): string {
  const zeroKey = `${baseKey}_zero`;
  const oneKey = `${baseKey}_one`;
  const otherKey = `${baseKey}_other`;
  const pack = getLocalePack(locale);
  let key = otherKey;
  if (count === 0 && pack.catalog[zeroKey]) key = zeroKey;
  else if (count === 1 && pack.catalog[oneKey]) key = oneKey;
  else if (pack.catalog[otherKey]) key = otherKey;
  else if (pack.catalog[oneKey]) key = oneKey;
  else key = baseKey;
  return t(key, locale, { count, ...vars });
}

export function formatDate(
  date: Date | string | number,
  locale: LocaleCode,
  style: "short" | "medium" | "long" = "medium",
  timeZone?: string
): string {
  const d = typeof date === "object" && date instanceof Date ? date : new Date(date);
  const pack = getLocalePack(locale);
  try {
    return new Intl.DateTimeFormat(pack.manifest.code, {
      dateStyle: style,
      timeZone: timeZone || "UTC",
    }).format(d);
  } catch {
    return d.toISOString().slice(0, 10);
  }
}

export function formatNumber(value: number, locale: LocaleCode): string {
  const pack = getLocalePack(locale);
  try {
    return new Intl.NumberFormat(pack.manifest.code).format(value);
  } catch {
    return String(value);
  }
}

export function formatCurrency(cents: number, locale: LocaleCode, currency?: string): string {
  const pack = getLocalePack(locale);
  const cur = currency || pack.manifest.currencyDefault || "USD";
  try {
    return new Intl.NumberFormat(pack.manifest.code, {
      style: "currency",
      currency: cur,
    }).format(cents / 100);
  } catch {
    return `${cur} ${(cents / 100).toFixed(2)}`;
  }
}

export function textDirection(locale: LocaleCode): "ltr" | "rtl" {
  return getLocalePack(locale).manifest.direction;
}

export function applyRegional(
  settings: RegionalSettings
): {
  locale: LocaleCode;
  dir: "ltr" | "rtl";
  sampleDate: string;
  sampleNumber: string;
  sampleCurrency: string;
  legalNotice: string;
  supportContact: string;
} {
  const locale = settings.language;
  return {
    locale,
    dir: textDirection(locale),
    sampleDate: formatDate(new Date(), locale, settings.dateFormat, settings.timezone),
    sampleNumber: formatNumber(12345.67, locale),
    sampleCurrency: formatCurrency(99900, locale, settings.currency),
    legalNotice: t(settings.legalNoticeKey, locale),
    supportContact: t(settings.supportContactKey, locale),
  };
}
