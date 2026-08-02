"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { DEFAULT_PHONE_ADS, type PhoneAd } from "@/content/phone-ads";
import type { PublicSiteContent } from "@/server/site-content/types";

const EMPTY: PublicSiteContent = {
  updatedAt: "",
  phoneAds: { rotateOnEnd: true, ads: DEFAULT_PHONE_ADS },
  hero: {
    backgroundMp4: "/media/hero-institutional.mp4",
    backgroundWebm: "/media/hero-institutional.webm",
    poster: "/brand/the-gold-mind-square.png",
    eyebrow: "",
    title: "",
    lead: "",
    ctaPrimaryLabel: "View Pricing",
    ctaPrimaryHref: "/pricing",
    ctaSecondaryLabel: "User Portal",
    ctaSecondaryHref: "/login",
  },
  logos: {
    header: "/brand/the-gold-mind-logo-header.png",
    footerGoldMind: "/brand/footer-gold-mind.png",
    footerRtasGroup: "/brand/footer-rtas-group.png",
    footerRtasDigital: "/brand/footer-rtas-digital.png",
  },
  header: {
    brandName: "THE GOLD MIND",
    brandSub: "Professional",
    ctaLabel: "User Portal",
    ctaHref: "/login",
  },
  footer: {
    description: "",
    copyrightLine: "",
    riskLine: "",
  },
};

const Ctx = createContext<PublicSiteContent>(EMPTY);

export function SiteContentProvider({
  initial,
  children,
}: {
  initial?: PublicSiteContent | null;
  children: ReactNode;
}) {
  const [content, setContent] = useState<PublicSiteContent>(initial || EMPTY);

  useEffect(() => {
    if (initial) setContent(initial);
  }, [initial]);

  useEffect(() => {
    let cancelled = false;
    fetch("/api/site-content/public", { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : null))
      .then((json) => {
        if (cancelled || !json?.ok) return;
        setContent({
          updatedAt: String(json.updatedAt || ""),
          phoneAds: {
            rotateOnEnd: json.phoneAds?.rotateOnEnd !== false,
            ads: Array.isArray(json.phoneAds?.ads) && json.phoneAds.ads.length
              ? (json.phoneAds.ads as PhoneAd[])
              : DEFAULT_PHONE_ADS,
          },
          hero: { ...EMPTY.hero, ...(json.hero || {}) },
          logos: { ...EMPTY.logos, ...(json.logos || {}) },
          header: { ...EMPTY.header, ...(json.header || {}) },
          footer: { ...EMPTY.footer, ...(json.footer || {}) },
        });
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  return <Ctx.Provider value={content}>{children}</Ctx.Provider>;
}

export function useSiteContent(): PublicSiteContent {
  return useContext(Ctx);
}
