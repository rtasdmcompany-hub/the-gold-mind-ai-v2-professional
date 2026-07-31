/**
 * Central product configuration — commercial / packaging / licensing constants.
 *
 * SINGLE SOURCE OF TRUTH for application name, edition, version, build, license
 * catalog, plans, payment provider, product URLs, MT5/installer names, locale
 * defaults, and feature flags.
 *
 * Brand identity (display name, emails, copyright) lives in `./brand`.
 * This module owns product *behavior* and *packaging* values.
 *
 * Override via NEXT_PUBLIC_PRODUCT_* / PRODUCT_* environment variables.
 * Do not hardcode these values elsewhere — import `{ product }` from here.
 */
import { brand } from "./brand";

function env(name: string, fallback = ""): string {
  const v = process.env[name];
  if (v === undefined || v === null) return fallback;
  const t = String(v).trim();
  return t.length ? t : fallback;
}

function firstEnv(names: string[], fallback: string): string {
  for (const n of names) {
    const v = env(n);
    if (v) return v;
  }
  return fallback;
}

function envInt(name: string, fallback: number): number {
  const n = Number(env(name, String(fallback)));
  return Number.isFinite(n) ? n : fallback;
}

function envBool(name: string, fallback: boolean): boolean {
  const v = env(name);
  if (!v) return fallback;
  const lower = v.toLowerCase();
  if (["1", "true", "yes", "on"].includes(lower)) return true;
  if (["0", "false", "no", "off"].includes(lower)) return false;
  return fallback;
}

export type ProductLicenseType = "trial" | "monthly" | "yearly" | "lifetime";
export type ProductPaymentProvider = "paddle" | "paypal" | "stripe" | "sandbox";

export type ProductPlan = {
  code: ProductLicenseType;
  /** Customer-facing plan / license label */
  label: string;
  /** Short license name for receipts */
  licenseName: string;
  amountCents: number;
  currency: string;
  /** Billing interval descriptor (e.g. 14d, month, year, once) */
  interval: string;
  seats: number;
  /** Days until expiry; null = never (lifetime) */
  durationDays: number | null;
};

const applicationName = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_APPLICATION_NAME", "PRODUCT_APPLICATION_NAME"],
  brand.productFullName
);

const edition = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_EDITION", "PRODUCT_EDITION"],
  "Professional"
);

const version = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_VERSION", "PRODUCT_VERSION", "NEXT_PUBLIC_BRAND_VERSION", "BRAND_VERSION"],
  brand.version
);

const buildNumber = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_BUILD_NUMBER", "PRODUCT_BUILD_NUMBER"],
  "26211"
);

const licenseName = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_LICENSE_NAME", "PRODUCT_LICENSE_NAME"],
  `${brand.productName} License`
);

const defaultCurrency = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_CURRENCY", "PRODUCT_CURRENCY"],
  "USD"
).toUpperCase();

const trialDays = envInt("NEXT_PUBLIC_PRODUCT_TRIAL_DAYS", envInt("PRODUCT_TRIAL_DAYS", 14));
const graceDaysDefault = envInt("LICENSE_GRACE_DAYS", envInt("PRODUCT_GRACE_DAYS", 7));

const plans: Record<ProductLicenseType, ProductPlan> = {
  trial: {
    code: "trial",
    label: firstEnv(["PRODUCT_PLAN_TRIAL_LABEL"], "Professional Trial"),
    licenseName: "Trial",
    amountCents: envInt("PRODUCT_PLAN_TRIAL_CENTS", 0),
    currency: defaultCurrency,
    interval: `${trialDays}d`,
    seats: envInt("PRODUCT_PLAN_TRIAL_SEATS", 1),
    durationDays: trialDays,
  },
  monthly: {
    code: "monthly",
    label: firstEnv(["PRODUCT_PLAN_MONTHLY_LABEL"], "Professional Monthly"),
    licenseName: "Monthly",
    amountCents: envInt("PRODUCT_PLAN_MONTHLY_CENTS", 9900),
    currency: defaultCurrency,
    interval: "month",
    seats: envInt("PRODUCT_PLAN_MONTHLY_SEATS", 2),
    durationDays: 30,
  },
  yearly: {
    code: "yearly",
    label: firstEnv(["PRODUCT_PLAN_YEARLY_LABEL"], "Professional Yearly"),
    licenseName: "Yearly",
    amountCents: envInt("PRODUCT_PLAN_YEARLY_CENTS", 89900),
    currency: defaultCurrency,
    interval: "year",
    seats: envInt("PRODUCT_PLAN_YEARLY_SEATS", 3),
    durationDays: 365,
  },
  lifetime: {
    code: "lifetime",
    label: firstEnv(["PRODUCT_PLAN_LIFETIME_LABEL"], "Professional Lifetime"),
    licenseName: "Lifetime",
    amountCents: envInt("PRODUCT_PLAN_LIFETIME_CENTS", 249900),
    currency: defaultCurrency,
    interval: "once",
    seats: envInt("PRODUCT_PLAN_LIFETIME_SEATS", 2),
    durationDays: null,
  },
};

const licenseTypes = Object.keys(plans) as ProductLicenseType[];

const paymentProvider = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_PAYMENT_PROVIDER", "PRODUCT_PAYMENT_PROVIDER", "PAYMENT_PROVIDER"],
  "paddle"
).toLowerCase() as ProductPaymentProvider;

const portalUrl = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_PORTAL_URL", "PRODUCT_PORTAL_URL", "NEXT_PUBLIC_APP_URL", "AUTH_URL", "NEXTAUTH_URL"],
  brand.website
).replace(/\/$/, "");

const apiBaseUrl = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_API_BASE_URL", "PRODUCT_API_BASE_URL"],
  `${portalUrl}/api`
).replace(/\/$/, "");

const supportUrl = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_SUPPORT_URL", "PRODUCT_SUPPORT_URL"],
  `${portalUrl}/contact`
);

const documentationUrl = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_DOCS_URL", "PRODUCT_DOCS_URL"],
  `${portalUrl}/docs`
);

const updateUrl = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_UPDATE_URL", "PRODUCT_UPDATE_URL"],
  `${portalUrl}/portal/downloads`
);

const mt5ProductName = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_MT5_NAME", "PRODUCT_MT5_NAME"],
  "TheGoldMindAI_Professional"
);

const mt5ExpertFile = firstEnv(
  ["PRODUCT_MT5_EXPERT_FILE"],
  `${mt5ProductName}.ex5`
);

const mt5SourceFile = firstEnv(
  ["PRODUCT_MT5_SOURCE_FILE"],
  `${mt5ProductName}.mq5`
);

const installerName = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_INSTALLER_NAME", "PRODUCT_INSTALLER_NAME"],
  "Setup.exe"
);

const installerZipName = firstEnv(
  ["PRODUCT_INSTALLER_ZIP_NAME"],
  `TGM_PROFESSIONAL_${version}_stable.zip`
);

const executableName = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_EXECUTABLE_NAME", "PRODUCT_EXECUTABLE_NAME"],
  "TGM-Professional-Launcher.exe"
);

const defaultLanguage = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_DEFAULT_LANGUAGE", "PRODUCT_DEFAULT_LANGUAGE"],
  "en"
).toLowerCase();

const timezone = firstEnv(
  ["NEXT_PUBLIC_PRODUCT_TIMEZONE", "PRODUCT_TIMEZONE"],
  "UTC"
);

const stablePackageId = firstEnv(["PRODUCT_STABLE_PACKAGE_ID"], "rel_100_stable");

/**
 * Canonical product object — import `{ product }` everywhere product config is needed.
 */
export const product = {
  /** Full application / product title */
  applicationName,
  /** Commercial edition lockup (e.g. Professional) */
  edition,
  /** Website edition display (e.g. THE GOLD MIND PROFESSIONAL (Website)) */
  websiteEditionLabel: `${brand.productName} (Website)`,
  /** Semver commercial version */
  version,
  /** Build / CI number */
  buildNumber,
  /** Generic license product name */
  licenseName,
  /** Ordered license / plan codes */
  licenseTypes,
  /** Default / primary license type for new paid checkouts */
  defaultLicenseType: "monthly" as ProductLicenseType,
  trialDays,
  graceDays: graceDaysDefault,
  /** Subscription / license plan catalog */
  plans,
  planOrder: ["trial", "monthly", "yearly", "lifetime"] as const satisfies readonly ProductLicenseType[],
  paymentProvider,
  urls: {
    support: supportUrl,
    documentation: documentationUrl,
    update: updateUrl,
    apiBase: apiBaseUrl,
    portal: portalUrl,
    pricing: `${portalUrl}/pricing`,
    downloads: `${portalUrl}/portal/downloads`,
  },
  mt5: {
    productName: mt5ProductName,
    expertFile: mt5ExpertFile,
    sourceFile: mt5SourceFile,
    platformLabel: "MetaTrader 5 Professional",
  },
  installer: {
    name: installerName,
    zipName: installerZipName,
    executableName,
    stablePackageId,
  },
  /** @deprecated use installer.executableName */
  executableName,
  defaultLanguage,
  defaultCurrency,
  timezone,
  featureFlags: {
    paddleCheckout: envBool("PRODUCT_FF_PADDLE_CHECKOUT", true),
    trialLicenses: envBool("PRODUCT_FF_TRIAL_LICENSES", true),
    lifetimeLicenses: envBool("PRODUCT_FF_LIFETIME_LICENSES", true),
    autoUpdate: envBool("PRODUCT_FF_AUTO_UPDATE", true),
    aiAssistant: envBool("PRODUCT_FF_AI_ASSISTANT", true),
    mobileCompanion: envBool("PRODUCT_FF_MOBILE_COMPANION", true),
    partnerProgram: envBool("PRODUCT_FF_PARTNER_PROGRAM", true),
    betaProgram: envBool("PRODUCT_FF_BETA_PROGRAM", true),
    marketEdition: envBool("PRODUCT_FF_MARKET_EDITION", true),
    googleOAuth: envBool("PRODUCT_FF_GOOGLE_OAUTH", true),
    emailDelivery: envBool("PRODUCT_FF_EMAIL_DELIVERY", true),
  },
} as const;

export type Product = typeof product;

/** Plan catalog shape used by billing UI / checkout. */
export function productPlanCatalog(): Record<
  ProductLicenseType,
  { label: string; amountCents: number; currency: string; interval: string }
> {
  const out = {} as Record<
    ProductLicenseType,
    { label: string; amountCents: number; currency: string; interval: string }
  >;
  for (const code of product.licenseTypes) {
    const p = product.plans[code];
    out[code] = {
      label: p.label,
      amountCents: p.amountCents,
      currency: p.currency,
      interval: p.interval,
    };
  }
  return out;
}

export function productSeatsForType(type: string): number {
  const key = String(type).toLowerCase() as ProductLicenseType;
  return product.plans[key]?.seats ?? 1;
}

export function productTrialDays(): number {
  return product.trialDays;
}

export function productGraceDays(): number {
  return product.graceDays;
}

export function productDurationDays(type: string): number | null {
  const key = String(type).toLowerCase() as ProductLicenseType;
  const plan = product.plans[key];
  return plan ? plan.durationDays : null;
}

export function productPackageLabel(type: string): string {
  const key = String(type).toLowerCase() as ProductLicenseType;
  const plan = product.plans[key];
  if (!plan) return type;
  if (key === "trial") return `Trial (${product.trialDays} days)`;
  return plan.licenseName;
}

export function isProductFeatureEnabled(
  flag: keyof typeof product.featureFlags
): boolean {
  return !!product.featureFlags[flag];
}

/** Plain JSON snapshot for docs / installer export. */
export function productExport(): Record<string, unknown> {
  return {
    applicationName: product.applicationName,
    edition: product.edition,
    version: product.version,
    buildNumber: product.buildNumber,
    licenseName: product.licenseName,
    licenseTypes: [...product.licenseTypes],
    trialDays: product.trialDays,
    graceDays: product.graceDays,
    plans: product.plans,
    paymentProvider: product.paymentProvider,
    urls: { ...product.urls },
    mt5: { ...product.mt5 },
    installer: { ...product.installer },
    executableName: product.executableName,
    defaultLanguage: product.defaultLanguage,
    defaultCurrency: product.defaultCurrency,
    timezone: product.timezone,
    featureFlags: { ...product.featureFlags },
  };
}
