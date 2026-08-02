import type { PhoneAd } from "@/content/phone-ads";

export type SitePhoneAds = {
  rotateOnEnd: boolean;
  ads: PhoneAd[];
};

export type SiteHeroContent = {
  backgroundMp4: string;
  backgroundWebm: string;
  poster: string;
  eyebrow: string;
  title: string;
  lead: string;
  ctaPrimaryLabel: string;
  ctaPrimaryHref: string;
  ctaSecondaryLabel: string;
  ctaSecondaryHref: string;
};

export type SiteLogos = {
  header: string;
  footerGoldMind: string;
  footerRtasGroup: string;
  footerRtasDigital: string;
};

export type SiteHeaderCopy = {
  brandName: string;
  brandSub: string;
  ctaLabel: string;
  ctaHref: string;
};

export type SiteFooterCopy = {
  description: string;
  copyrightLine: string;
  riskLine: string;
};

/** Full admin-editable website content (commercial only). */
export type SiteContentData = {
  version: 1;
  updatedAt: string;
  phoneAds: SitePhoneAds;
  hero: SiteHeroContent;
  logos: SiteLogos;
  header: SiteHeaderCopy;
  footer: SiteFooterCopy;
};

/** Public payload consumed by marketing pages. */
export type PublicSiteContent = Omit<SiteContentData, "version">;

export type StoredMediaObject = {
  id: string;
  filename: string;
  contentType: string;
  /** Base64 payload — only for small assets when Blob/local FS unavailable. */
  base64: string;
  size: number;
  createdAt: string;
};

export type MediaStoreData = {
  version: 1;
  items: Record<string, StoredMediaObject>;
};
