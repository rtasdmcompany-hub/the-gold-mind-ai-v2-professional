/**
 * Localization types — commercial i18n only (Core-independent).
 */
export type LocaleCode = "en" | "ur" | "ar" | "fr" | "de" | "es" | "tr" | string;

export type TextDirection = "ltr" | "rtl";

export interface LocaleManifest {
  code: LocaleCode;
  name: string;
  nativeName: string;
  version: string;
  direction: TextDirection;
  fallback: LocaleCode;
  currencyDefault: string;
  dateStyle: "short" | "medium" | "long";
  namespaces: string[];
}

export interface RegionalSettings {
  language: LocaleCode;
  timezone: string;
  dateFormat: "short" | "medium" | "long";
  currency: string;
  measurement: "metric" | "imperial";
  legalNoticeKey: string;
  supportContactKey: string;
}

export type TranslationCatalog = Record<string, string>;

export type TranslationStatus = "draft" | "in_review" | "approved" | "published";

export interface TranslationReviewItem {
  id: string;
  locale: LocaleCode;
  key: string;
  source: string;
  proposed: string;
  status: TranslationStatus;
  reviewer?: string;
  updatedAt: string;
}

export const I18N_NAMESPACES = [
  "common",
  "website",
  "portal",
  "admin",
  "partner",
  "installer",
  "updater",
  "emails",
  "knowledge",
  "support",
  "errors",
  "notifications",
  "docs",
  "legal",
  "regional",
] as const;

export type I18nNamespace = (typeof I18N_NAMESPACES)[number];
