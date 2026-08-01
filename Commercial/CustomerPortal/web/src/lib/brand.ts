/**
 * Central customer-facing brand configuration.
 *
 * SINGLE SOURCE OF TRUTH for brand name, company, product, version, domain,
 * website, emails, copyright, and social links.
 *
 * Override any value via environment (prefer NEXT_PUBLIC_BRAND_* for display
 * strings so Client Components stay consistent). Defaults are THE GOLD MIND
 * placeholders until custom domain cutover.
 *
 * Do not hardcode brand strings elsewhere — import from this module.
 */
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

const DEFAULT_DOMAIN = "thegoldmind.ai";
const DEFAULT_PORTAL =
  "https://the-gold-mind-ai-v2-professional.vercel.app";

/** Email / public domain (no protocol). */
export const brandDomain = firstEnv(
  ["NEXT_PUBLIC_BRAND_DOMAIN", "BRAND_DOMAIN"],
  DEFAULT_DOMAIN
);

const brandName = firstEnv(
  ["NEXT_PUBLIC_BRAND_NAME", "BRAND_NAME"],
  "THE GOLD MIND"
);
const companyName = firstEnv(
  ["NEXT_PUBLIC_BRAND_COMPANY", "BRAND_COMPANY"],
  brandName
);
const productName = firstEnv(
  ["NEXT_PUBLIC_BRAND_PRODUCT", "BRAND_PRODUCT"],
  "THE GOLD MIND PROFESSIONAL"
);
const productFullName = firstEnv(
  ["NEXT_PUBLIC_BRAND_PRODUCT_FULL", "BRAND_PRODUCT_FULL"],
  "THE GOLD MIND AI v2.0 PROFESSIONAL"
);
const productShortName = firstEnv(
  ["NEXT_PUBLIC_BRAND_PRODUCT_SHORT", "BRAND_PRODUCT_SHORT"],
  brandName
);
const version = firstEnv(
  ["NEXT_PUBLIC_BRAND_VERSION", "BRAND_VERSION", "npm_package_version"],
  "1.0.0"
);
const tagline = firstEnv(
  ["NEXT_PUBLIC_BRAND_TAGLINE", "BRAND_TAGLINE"],
  "Automated Trading Software"
);
const productId = firstEnv(
  ["NEXT_PUBLIC_BRAND_PRODUCT_ID", "BRAND_PRODUCT_ID"],
  "the-gold-mind-ai-v2-professional"
);

const website = firstEnv(
  [
    "NEXT_PUBLIC_BRAND_WEBSITE",
    "BRAND_WEBSITE",
    "NEXT_PUBLIC_APP_URL",
    "AUTH_URL",
    "NEXTAUTH_URL",
  ],
  DEFAULT_PORTAL
).replace(/\/$/, "");

// Prefer dedicated brand email envs. Generic SUPPORT_EMAIL is used only by
// delivery routes as an inbox override — not as the customer-facing brand address.
const supportEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_SUPPORT_EMAIL", "BRAND_SUPPORT_EMAIL"],
  `support@${brandDomain}`
);
const billingEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_BILLING_EMAIL", "BILLING_EMAIL"],
  `billing@${brandDomain}`
);
const licenseEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_LICENSE_EMAIL", "LICENSE_EMAIL"],
  `license@${brandDomain}`
);
const adminEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_ADMIN_EMAIL", "ADMIN_EMAIL"],
  `admin@${brandDomain}`
);
const noreplyEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_NOREPLY_EMAIL", "BRAND_NOREPLY_EMAIL"],
  `noreply@${brandDomain}`
);
const privacyEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_PRIVACY_EMAIL", "PRIVACY_EMAIL"],
  `privacy@${brandDomain}`
);
const legalEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_LEGAL_EMAIL", "LEGAL_EMAIL"],
  `legal@${brandDomain}`
);
const partnersEmail = firstEnv(
  ["NEXT_PUBLIC_BRAND_PARTNERS_EMAIL", "PARTNERS_EMAIL"],
  `partners@${brandDomain}`
);

const copyrightYear = firstEnv(
  ["NEXT_PUBLIC_BRAND_COPYRIGHT_YEAR", "BRAND_COPYRIGHT_YEAR"],
  String(new Date().getFullYear())
);

const socialTwitter = env("NEXT_PUBLIC_BRAND_SOCIAL_TWITTER", "");
const socialLinkedin = env("NEXT_PUBLIC_BRAND_SOCIAL_LINKEDIN", "");
const socialYoutube = env("NEXT_PUBLIC_BRAND_SOCIAL_YOUTUBE", "");
const socialFacebook = env("NEXT_PUBLIC_BRAND_SOCIAL_FACEBOOK", "");
const socialX = env("NEXT_PUBLIC_BRAND_SOCIAL_X", socialTwitter);

const mobileBundleId = firstEnv(
  ["NEXT_PUBLIC_BRAND_MOBILE_BUNDLE_ID", "BRAND_MOBILE_BUNDLE_ID"],
  "com.thegoldmind.companion"
);

const defaultDescription = `${productFullName} — Customer Portal, licensing, downloads, and certified automated trading software. Trading involves risk of loss.`;

/**
 * Canonical brand object — import `{ brand }` everywhere customer-facing
 * identity is needed.
 */
export const brand = {
  /** Short brand / trade name */
  brandName,
  /** Legal / company display name */
  companyName,
  /** Commercial product lockup (e.g. THE GOLD MIND PROFESSIONAL) */
  productName,
  /** Full product title including edition (e.g. THE GOLD MIND AI v2.0 PROFESSIONAL) */
  productFullName,
  /** Alias for brandName */
  productShortName,
  /** Product slug / id */
  productId,
  /** Commercial version */
  version,
  /** Tagline */
  tagline,
  /** Public email/web domain host */
  domain: brandDomain,
  /** Public website / portal base URL (no trailing slash) */
  website,
  /** Support URL */
  supportUrl: `${website}/contact`,
  /** Downloads URL */
  downloadsUrl: `${website}/portal/downloads`,

  emails: {
    support: supportEmail,
    billing: billingEmail,
    license: licenseEmail,
    admin: adminEmail,
    noreply: noreplyEmail,
    privacy: privacyEmail,
    legal: legalEmail,
    partners: partnersEmail,
  },

  /**
   * Resend / transactional From header.
   * Prefer RESEND_FROM_EMAIL when set (ops may use a verified cutover domain
   * until thegoldmind.ai DNS + Resend verification are complete).
   */
  resendFrom: (() => {
    const fromEnv = env("RESEND_FROM_EMAIL");
    if (fromEnv) return fromEnv;
    return `${productName} <${noreplyEmail}>`;
  })(),

  social: {
    twitter: socialTwitter,
    x: socialX,
    linkedin: socialLinkedin,
    youtube: socialYoutube,
    facebook: socialFacebook,
  },

  copyrightYear,
  /** e.g. © 2026 THE GOLD MIND */
  copyright: `© ${copyrightYear} ${companyName}`,
  /** e.g. © 2026 THE GOLD MIND PROFESSIONAL */
  copyrightProduct: `© ${copyrightYear} ${productName}`,
  copyrightNotice: `© ${copyrightYear} ${companyName}. All rights reserved.`,

  description: firstEnv(
    ["NEXT_PUBLIC_BRAND_DESCRIPTION", "BRAND_DESCRIPTION"],
    defaultDescription
  ),
  ogDescription: firstEnv(
    ["NEXT_PUBLIC_BRAND_OG_DESCRIPTION"],
    "Official website and Customer Portal — licenses, downloads, and certified Core."
  ),
  riskLine: firstEnv(
    ["NEXT_PUBLIC_BRAND_RISK_LINE"],
    "Trading involves substantial risk of loss."
  ),
  emailSignature: `— ${productName}`,
  supportContactLine: `${partnersEmail} · ${supportEmail}`,

  mobile: {
    bundleId: mobileBundleId,
    androidPackage: mobileBundleId,
  },

  assets: {
    icon32: "/brand/the-gold-mind-icon-32.png",
    icon192: "/brand/the-gold-mind-icon-192.png",
    icon180: "/brand/the-gold-mind-icon-180.png",
    og: "/brand/the-gold-mind-og-1200x630.png",
    twitter: "/brand/the-gold-mind-twitter-1200x600.png",
    footer: "/brand/footer-gold-mind.png",
    favicon: "/favicon.ico",
  },
} as const;

export type Brand = typeof brand;

/** Tokens for i18n `{productName}` style interpolation. */
export function brandTokens(): Record<string, string> {
  return {
    brandName: brand.brandName,
    companyName: brand.companyName,
    productName: brand.productName,
    productFullName: brand.productFullName,
    productShortName: brand.productShortName,
    version: brand.version,
    tagline: brand.tagline,
    domain: brand.domain,
    website: brand.website,
    supportEmail: brand.emails.support,
    billingEmail: brand.emails.billing,
    licenseEmail: brand.emails.license,
    adminEmail: brand.emails.admin,
    noreplyEmail: brand.emails.noreply,
    privacyEmail: brand.emails.privacy,
    legalEmail: brand.emails.legal,
    partnersEmail: brand.emails.partners,
    copyright: brand.copyright,
    copyrightProduct: brand.copyrightProduct,
    copyrightYear: brand.copyrightYear,
    emailSignature: brand.emailSignature,
    supportContact: brand.supportContactLine,
    riskLine: brand.riskLine,
  };
}

/** Apply `{token}` replacements using brandTokens (+ optional extras). */
export function applyBrandTemplate(
  template: string,
  extra?: Record<string, string | number>
): string {
  const vars: Record<string, string | number> = { ...brandTokens(), ...extra };
  return template.replace(/\{(\w+)\}/g, (_, k: string) =>
    vars[k] !== undefined ? String(vars[k]) : `{${k}}`
  );
}

/** Plain JSON snapshot for installer / docs export scripts. */
export function brandExport(): Record<string, unknown> {
  return {
    brandName: brand.brandName,
    companyName: brand.companyName,
    productName: brand.productName,
    productFullName: brand.productFullName,
    productShortName: brand.productShortName,
    productId: brand.productId,
    version: brand.version,
    tagline: brand.tagline,
    domain: brand.domain,
    website: brand.website,
    emails: { ...brand.emails },
    resendFrom: brand.resendFrom,
    social: { ...brand.social },
    copyrightYear: brand.copyrightYear,
    copyright: brand.copyright,
    copyrightProduct: brand.copyrightProduct,
    copyrightNotice: brand.copyrightNotice,
    description: brand.description,
    mobile: { ...brand.mobile },
  };
}

/* ── Backward-compatible aliases (prefer `brand.*`) ───────────────────── */

export const BRAND_PRODUCT = brand.productName;
export const BRAND_PRODUCT_SHORT = brand.productShortName;
export const BRAND_PRODUCT_FULL = brand.productFullName;
export const BRAND_EMAIL_DOMAIN = brand.domain;
export const BRAND_EMAILS = brand.emails;
export const BRAND_RESEND_FROM = brand.resendFrom;
export const BRAND_SUPPORT_CONTACT = brand.supportContactLine;
export const BRAND_PORTAL_FALLBACK_URL = brand.website;
