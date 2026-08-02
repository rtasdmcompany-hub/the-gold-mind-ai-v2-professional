/**
 * Homepage iPhone panel ads.
 *
 * Videos + posters live in: public/media/phone-ads/
 * Manifest (owner-editable): public/media/phone-ads/ads.json
 *
 * This module also exports a typed fallback so the panel always has the
 * MQL5 Market ad even if ads.json fails to load.
 */

export type PhoneAd = {
  id: string;
  enabled: boolean;
  title: string;
  /** Short optional line shown on the phone. Empty string hides the line. */
  details?: string;
  /** Click-through URL (opens in a new tab). */
  href: string;
  video: string;
  poster: string;
};

export type PhoneAdsManifest = {
  rotateOnEnd?: boolean;
  ads: PhoneAd[];
};

export const PHONE_ADS_MANIFEST_URL = "/media/phone-ads/ads.json";

/** Built-in fallback — keep in sync with public/media/phone-ads/ads.json */
export const DEFAULT_PHONE_ADS: PhoneAd[] = [
  {
    id: "mql5-market",
    enabled: true,
    title: "THE GOLD MIND — MQL5 Market",
    details: "Available on MQL5 Market",
    href: "https://www.mql5.com/en/market/product/183685?source=Site+Market+MT5+Search+Rating007%3athe+gold+mind",
    video: "/media/phone-ads/mql5-market.mp4",
    poster: "/media/phone-ads/mql5-market-poster.jpg",
  },
];

export function normalizePhoneAds(raw: unknown): PhoneAd[] {
  if (!raw || typeof raw !== "object") return DEFAULT_PHONE_ADS;
  const ads = (raw as PhoneAdsManifest).ads;
  if (!Array.isArray(ads) || ads.length === 0) return DEFAULT_PHONE_ADS;

  const cleaned = ads
    .filter((a) => a && typeof a === "object")
    .map((a) => ({
      id: String(a.id || "").trim(),
      enabled: a.enabled !== false,
      title: String(a.title || "").trim() || "Product ad",
      details: String(a.details || "").trim(),
      href: String(a.href || "").trim(),
      video: String(a.video || "").trim(),
      poster: String(a.poster || "").trim(),
    }))
    .filter((a) => a.id && a.href && a.video && a.poster && a.enabled);

  return cleaned.length ? cleaned : DEFAULT_PHONE_ADS;
}
