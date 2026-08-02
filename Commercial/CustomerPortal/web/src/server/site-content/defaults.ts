import { DEFAULT_PHONE_ADS } from "@/content/phone-ads";
import { brand } from "@/lib/brand";
import type { SiteContentData } from "./types";

export function defaultSiteContent(): SiteContentData {
  return {
    version: 1,
    updatedAt: new Date(0).toISOString(),
    phoneAds: {
      rotateOnEnd: true,
      ads: DEFAULT_PHONE_ADS.map((a) => ({ ...a })),
    },
    hero: {
      backgroundMp4: "/media/hero-institutional.mp4",
      backgroundWebm: "/media/hero-institutional.webm",
      poster: "/brand/the-gold-mind-square.png",
      eyebrow: brand.productFullName,
      title: "Institutional AI Trading Software",
      lead:
        "Systematic MetaTrader 5 automation with certified Core integrity, enterprise licensing, and global infrastructure.",
      ctaPrimaryLabel: "View Pricing",
      ctaPrimaryHref: "/pricing",
      ctaSecondaryLabel: "User Portal",
      ctaSecondaryHref: "/login",
    },
    logos: {
      header: "/brand/the-gold-mind-logo-header.png",
      footerGoldMind: brand.assets.footer,
      footerRtasGroup: brand.assets.footerRtasGroup,
      footerRtasDigital: brand.assets.footerRtasDigital,
    },
    header: {
      brandName: brand.brandName,
      brandSub: "Professional",
      ctaLabel: "User Portal",
      ctaHref: "/login",
    },
    footer: {
      description: `${brand.brandName} Professional — institutional automated trading software for MetaTrader 5.`,
      copyrightLine:
        `© ${brand.copyrightYear} RTAS Digital Marketing Company. All rights reserved. RTAS Studio AI is developed and operated by RTAS Digital Marketing Company. Part of the RTAS brand ecosystem.`,
      riskLine: brand.riskLine,
    },
  };
}
