/**
 * THE GOLD MIND PROFESSIONAL — customer-facing brand constants.
 * Infrastructure accounts (Resend/Google/Paddle/Upstash) may be shared company accounts;
 * all customer-visible identity must use these values only.
 *
 * When the production domain is live, update BRAND_EMAIL_DOMAIN (and env) once.
 */
export const BRAND_PRODUCT = "THE GOLD MIND PROFESSIONAL";
export const BRAND_PRODUCT_SHORT = "THE GOLD MIND";
export const BRAND_PRODUCT_FULL = "THE GOLD MIND AI v2.0 PROFESSIONAL";

/** Temporary placeholders until custom domain DNS is cut over. */
export const BRAND_EMAIL_DOMAIN = "thegoldmind.ai";

export const BRAND_EMAILS = {
  support: `support@${BRAND_EMAIL_DOMAIN}`,
  admin: `admin@${BRAND_EMAIL_DOMAIN}`,
  billing: `billing@${BRAND_EMAIL_DOMAIN}`,
  license: `license@${BRAND_EMAIL_DOMAIN}`,
  privacy: `privacy@${BRAND_EMAIL_DOMAIN}`,
  legal: `legal@${BRAND_EMAIL_DOMAIN}`,
  noreply: `noreply@${BRAND_EMAIL_DOMAIN}`,
  partners: `partners@${BRAND_EMAIL_DOMAIN}`,
} as const;

/** Default Resend From header (requires thegoldmind.ai verified on Resend). */
export const BRAND_RESEND_FROM = `${BRAND_PRODUCT} <${BRAND_EMAILS.noreply}>`;

export const BRAND_SUPPORT_CONTACT = `${BRAND_EMAILS.partners} · ${BRAND_EMAILS.support}`;

export const BRAND_PORTAL_FALLBACK_URL = "https://the-gold-mind-ai-v2-professional.vercel.app";
