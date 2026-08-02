"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import type { PhoneAd } from "@/content/phone-ads";
import {
  ensureSiteContentLoaded,
  flushSiteContent,
  normalizePhoneAdsForAdmin,
  readSiteContent,
  saveSiteContent,
} from "./store";

function revalidateSite() {
  revalidatePath("/");
  revalidatePath("/portal/admin/site-content");
  revalidatePath("/api/site-content/public");
}

export async function actionSavePhoneAds(formData: FormData): Promise<void> {
  await requirePermission("admin.launch.write");
  await ensureSiteContentLoaded();

  const rotateOnEnd = String(formData.get("rotateOnEnd") || "") === "on";
  const raw = String(formData.get("adsJson") || "").trim();
  let ads: PhoneAd[] = [];
  try {
    const parsed = JSON.parse(raw) as unknown;
    ads = normalizePhoneAdsForAdmin({ ads: parsed });
  } catch {
    ads = readSiteContent().phoneAds.ads;
  }

  saveSiteContent({
    phoneAds: { rotateOnEnd, ads },
  });
  await flushSiteContent();
  revalidateSite();
}

export async function actionSaveHero(formData: FormData): Promise<void> {
  await requirePermission("admin.launch.write");
  await ensureSiteContentLoaded();
  saveSiteContent({
    hero: {
      backgroundMp4: String(formData.get("backgroundMp4") || ""),
      backgroundWebm: String(formData.get("backgroundWebm") || ""),
      poster: String(formData.get("poster") || ""),
      eyebrow: String(formData.get("eyebrow") || ""),
      title: String(formData.get("title") || ""),
      lead: String(formData.get("lead") || ""),
      ctaPrimaryLabel: String(formData.get("ctaPrimaryLabel") || ""),
      ctaPrimaryHref: String(formData.get("ctaPrimaryHref") || ""),
      ctaSecondaryLabel: String(formData.get("ctaSecondaryLabel") || ""),
      ctaSecondaryHref: String(formData.get("ctaSecondaryHref") || ""),
    },
  });
  await flushSiteContent();
  revalidateSite();
}

export async function actionSaveLogos(formData: FormData): Promise<void> {
  await requirePermission("admin.launch.write");
  await ensureSiteContentLoaded();
  saveSiteContent({
    logos: {
      header: String(formData.get("header") || ""),
      footerGoldMind: String(formData.get("footerGoldMind") || ""),
      footerRtasGroup: String(formData.get("footerRtasGroup") || ""),
      footerRtasDigital: String(formData.get("footerRtasDigital") || ""),
    },
  });
  await flushSiteContent();
  revalidateSite();
}

export async function actionSaveHeaderFooter(formData: FormData): Promise<void> {
  await requirePermission("admin.launch.write");
  await ensureSiteContentLoaded();
  saveSiteContent({
    header: {
      brandName: String(formData.get("brandName") || ""),
      brandSub: String(formData.get("brandSub") || ""),
      ctaLabel: String(formData.get("ctaLabel") || ""),
      ctaHref: String(formData.get("ctaHref") || ""),
    },
    footer: {
      description: String(formData.get("description") || ""),
      copyrightLine: String(formData.get("copyrightLine") || ""),
      riskLine: String(formData.get("riskLine") || ""),
    },
  });
  await flushSiteContent();
  revalidateSite();
}

export async function actionResetSiteContentSection(formData: FormData): Promise<void> {
  await requirePermission("admin.launch.write");
  await ensureSiteContentLoaded();
  const section = String(formData.get("section") || "").trim();
  const { defaultSiteContent } = await import("./defaults");
  const defaults = defaultSiteContent();
  if (section === "phoneAds") saveSiteContent({ phoneAds: defaults.phoneAds });
  else if (section === "hero") saveSiteContent({ hero: defaults.hero });
  else if (section === "logos") saveSiteContent({ logos: defaults.logos });
  else if (section === "headerFooter") {
    saveSiteContent({ header: defaults.header, footer: defaults.footer });
  } else if (section === "all") {
    saveSiteContent(defaults);
  }
  await flushSiteContent();
  revalidateSite();
}
