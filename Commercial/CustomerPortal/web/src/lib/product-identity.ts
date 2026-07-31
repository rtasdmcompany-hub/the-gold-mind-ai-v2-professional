/** Canonical product + brand identity re-exports. */
export {
  brand,
  BRAND_PRODUCT,
  BRAND_PRODUCT_FULL,
  BRAND_PRODUCT_SHORT,
  BRAND_PORTAL_FALLBACK_URL,
} from "./brand";

export {
  product,
  productExport,
  productPlanCatalog,
  productSeatsForType,
  productTrialDays,
  productGraceDays,
  productPackageLabel,
  isProductFeatureEnabled,
} from "./product";

import { brand } from "./brand";
import { product } from "./product";

export const PRODUCT_ID = brand.productId;
export const PRODUCT_NAME = product.applicationName;
export const PRODUCT_VERSION = product.version;
export const PRODUCT_BUILD = product.buildNumber;
export const PRODUCTION_URL = product.urls.portal;

/** Infrastructure account paths (not customer-facing product config). */
export const GITHUB_REPO = "rtasdmcompany-hub/the-gold-mind-ai-v2-professional" as const;
export const VERCEL_PROJECT = "rtas-group/the-gold-mind-ai-v2-professional" as const;
