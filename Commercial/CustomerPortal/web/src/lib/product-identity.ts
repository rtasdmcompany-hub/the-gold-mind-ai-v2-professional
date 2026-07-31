/** Canonical product identity — re-exports central brand config. */
export {
  brand,
  BRAND_PRODUCT,
  BRAND_PRODUCT_FULL,
  BRAND_PRODUCT_SHORT,
  BRAND_PORTAL_FALLBACK_URL,
} from "./brand";

import { brand } from "./brand";

export const PRODUCT_ID = brand.productId;
export const PRODUCT_NAME = brand.productFullName;
export const PRODUCTION_URL = brand.website;

/** Infrastructure account paths (not customer-facing brand). */
export const GITHUB_REPO = "rtasdmcompany-hub/the-gold-mind-ai-v2-professional" as const;
export const VERCEL_PROJECT = "rtas-group/the-gold-mind-ai-v2-professional" as const;
