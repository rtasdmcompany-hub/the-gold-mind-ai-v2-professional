/**
 * Website Site Content CMS — durable JSON store (+ Upstash when configured).
 * Edits phone ads, hero media/copy, logos, header/footer lines.
 * Never touches Trading Engine / Core.
 */
import fs from "fs";
import path from "path";
import { commercialDataRoot } from "@/server/cloud/data-root";
import {
  durableGet,
  durableSet,
  isDurableStoreConfigured,
} from "@/server/cloud/cache";
import { DEFAULT_PHONE_ADS, type PhoneAd } from "@/content/phone-ads";
import {
  blobGetMediaIndex,
  blobGetSiteContent,
  blobSetMediaIndex,
  blobSetSiteContent,
  isBlobPersistConfigured,
} from "./blob-persist";
import { defaultSiteContent } from "./defaults";
import type {
  MediaStoreData,
  PublicSiteContent,
  SiteContentData,
  SiteFooterCopy,
  SiteHeaderCopy,
  SiteHeroContent,
  SiteLogos,
  SitePhoneAds,
  StoredMediaObject,
} from "./types";

const CONTENT_KEY = "tgm:site-content:store:v1";
const MEDIA_KEY = "tgm:site-content:media:v1";

let contentCache: SiteContentData | null = null;
let mediaCache: MediaStoreData | null = null;
let contentLoad: Promise<void> | null = null;
let mediaLoad: Promise<void> | null = null;
let writeChain: Promise<void> = Promise.resolve();

function contentPath(): string {
  const dir = commercialDataRoot("site-content");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "site-content.json");
}

function mediaPath(): string {
  const dir = commercialDataRoot("site-content");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "media-index.json");
}

function loadContentDisk(): SiteContentData {
  const p = contentPath();
  if (!fs.existsSync(p)) return defaultSiteContent();
  try {
    return normalizeContent(JSON.parse(fs.readFileSync(p, "utf8")));
  } catch {
    return defaultSiteContent();
  }
}

function loadMediaDisk(): MediaStoreData {
  const p = mediaPath();
  if (!fs.existsSync(p)) return { version: 1, items: {} };
  try {
    const data = JSON.parse(fs.readFileSync(p, "utf8")) as MediaStoreData;
    if (!data.items || typeof data.items !== "object") data.items = {};
    return data;
  } catch {
    return { version: 1, items: {} };
  }
}

function str(v: unknown, fallback = ""): string {
  return typeof v === "string" ? v.trim() : fallback;
}

/** Admin-facing normalize — keeps playlist items until admin deletes (id required). */
export function normalizePhoneAdsForAdmin(raw: unknown): PhoneAd[] {
  if (!raw || typeof raw !== "object") return DEFAULT_PHONE_ADS.map((a) => ({ ...a }));
  const ads = (raw as { ads?: unknown }).ads;
  // Empty array is intentional (admin cleared playlist) — do not force defaults here.
  if (!Array.isArray(ads)) return DEFAULT_PHONE_ADS.map((a) => ({ ...a }));
  return ads
    .filter((a) => a && typeof a === "object")
    .map((a, i) => {
      const row = a as Partial<PhoneAd>;
      const id = str(row.id) || `ad_${Date.now().toString(36)}_${i}`;
      return {
        id,
        enabled: row.enabled !== false,
        title: str(row.title) || `Ad ${i + 1}`,
        details: str(row.details),
        href: str(row.href) || "#",
        video: str(row.video),
        poster: str(row.poster),
      };
    })
    .filter((a) => a.id);
}

function normalizeHero(raw: unknown, base: SiteHeroContent): SiteHeroContent {
  const o = (raw && typeof raw === "object" ? raw : {}) as Partial<SiteHeroContent>;
  return {
    backgroundMp4: str(o.backgroundMp4, base.backgroundMp4) || base.backgroundMp4,
    backgroundWebm: str(o.backgroundWebm, base.backgroundWebm) || base.backgroundWebm,
    poster: str(o.poster, base.poster) || base.poster,
    eyebrow: str(o.eyebrow, base.eyebrow) || base.eyebrow,
    title: str(o.title, base.title) || base.title,
    lead: str(o.lead, base.lead) || base.lead,
    ctaPrimaryLabel: str(o.ctaPrimaryLabel, base.ctaPrimaryLabel) || base.ctaPrimaryLabel,
    ctaPrimaryHref: str(o.ctaPrimaryHref, base.ctaPrimaryHref) || base.ctaPrimaryHref,
    ctaSecondaryLabel: str(o.ctaSecondaryLabel, base.ctaSecondaryLabel) || base.ctaSecondaryLabel,
    ctaSecondaryHref: str(o.ctaSecondaryHref, base.ctaSecondaryHref) || base.ctaSecondaryHref,
  };
}

function normalizeLogos(raw: unknown, base: SiteLogos): SiteLogos {
  const o = (raw && typeof raw === "object" ? raw : {}) as Partial<SiteLogos>;
  return {
    header: str(o.header, base.header) || base.header,
    footerGoldMind: str(o.footerGoldMind, base.footerGoldMind) || base.footerGoldMind,
    footerRtasGroup: str(o.footerRtasGroup, base.footerRtasGroup) || base.footerRtasGroup,
    footerRtasDigital: str(o.footerRtasDigital, base.footerRtasDigital) || base.footerRtasDigital,
  };
}

function normalizeHeader(raw: unknown, base: SiteHeaderCopy): SiteHeaderCopy {
  const o = (raw && typeof raw === "object" ? raw : {}) as Partial<SiteHeaderCopy>;
  return {
    brandName: str(o.brandName, base.brandName) || base.brandName,
    brandSub: str(o.brandSub, base.brandSub) || base.brandSub,
    ctaLabel: str(o.ctaLabel, base.ctaLabel) || base.ctaLabel,
    ctaHref: str(o.ctaHref, base.ctaHref) || base.ctaHref,
  };
}

function normalizeFooter(raw: unknown, base: SiteFooterCopy): SiteFooterCopy {
  const o = (raw && typeof raw === "object" ? raw : {}) as Partial<SiteFooterCopy>;
  return {
    description: str(o.description, base.description) || base.description,
    copyrightLine: str(o.copyrightLine, base.copyrightLine) || base.copyrightLine,
    riskLine: str(o.riskLine, base.riskLine) || base.riskLine,
  };
}

export function normalizeContent(raw: unknown): SiteContentData {
  const base = defaultSiteContent();
  if (!raw || typeof raw !== "object") return base;
  const o = raw as Partial<SiteContentData>;
  const phoneRaw = o.phoneAds;
  const ads =
    phoneRaw && typeof phoneRaw === "object"
      ? normalizePhoneAdsForAdmin(phoneRaw)
      : base.phoneAds.ads;
  return {
    version: 1,
    updatedAt: str(o.updatedAt, base.updatedAt) || new Date().toISOString(),
    phoneAds: {
      rotateOnEnd: !phoneRaw || typeof phoneRaw !== "object" ? true : (phoneRaw as SitePhoneAds).rotateOnEnd !== false,
      // Preserve empty playlist (admin deleted all). Defaults only when phoneAds missing.
      ads: phoneRaw && typeof phoneRaw === "object" && Array.isArray((phoneRaw as SitePhoneAds).ads) ? ads : base.phoneAds.ads,
    },
    hero: normalizeHero(o.hero, base.hero),
    logos: normalizeLogos(o.logos, base.logos),
    header: normalizeHeader(o.header, base.header),
    footer: normalizeFooter(o.footer, base.footer),
  };
}

export async function ensureSiteContentLoaded(): Promise<void> {
  if (contentCache) return;
  if (!contentLoad) {
    contentLoad = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(CONTENT_KEY);
          if (remote) {
            contentCache = normalizeContent(JSON.parse(remote));
            return;
          }
        } catch {
          /* fall through */
        }
      }
      // Vercel Blob fallback (production has Blob but may not have Upstash).
      try {
        const fromBlob = await blobGetSiteContent();
        if (fromBlob) {
          contentCache = normalizeContent(JSON.parse(fromBlob));
          return;
        }
      } catch {
        /* fall through */
      }
      contentCache = loadContentDisk();
      if (isDurableStoreConfigured()) {
        try {
          await durableSet(CONTENT_KEY, JSON.stringify(contentCache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      if (!contentCache) contentLoad = null;
    });
  }
  await contentLoad;
  if (!contentCache) contentCache = defaultSiteContent();
}

export async function ensureMediaStoreLoaded(): Promise<void> {
  if (mediaCache) return;
  if (!mediaLoad) {
    mediaLoad = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(MEDIA_KEY);
          if (remote) {
            mediaCache = JSON.parse(remote) as MediaStoreData;
            if (!mediaCache.items) mediaCache.items = {};
            return;
          }
        } catch {
          /* fall through */
        }
      }
      try {
        const fromBlob = await blobGetMediaIndex();
        if (fromBlob) {
          mediaCache = JSON.parse(fromBlob) as MediaStoreData;
          if (!mediaCache.items) mediaCache.items = {};
          return;
        }
      } catch {
        /* fall through */
      }
      mediaCache = loadMediaDisk();
      if (isDurableStoreConfigured()) {
        try {
          await durableSet(MEDIA_KEY, JSON.stringify(mediaCache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      if (!mediaCache) mediaLoad = null;
    });
  }
  await mediaLoad;
  if (!mediaCache) mediaCache = { version: 1, items: {} };
}

function persistContent(data: SiteContentData): void {
  contentCache = data;
  const blob = JSON.stringify(data, null, 2);
  writeChain = writeChain.then(async () => {
    try {
      fs.writeFileSync(contentPath(), blob, "utf8");
    } catch {
      /* serverless */
    }
    if (isDurableStoreConfigured()) {
      await durableSet(CONTENT_KEY, blob);
    }
    await blobSetSiteContent(blob);
  });
}

function persistMedia(data: MediaStoreData): void {
  mediaCache = data;
  const blob = JSON.stringify(data);
  writeChain = writeChain.then(async () => {
    try {
      fs.writeFileSync(mediaPath(), blob, "utf8");
    } catch {
      /* serverless */
    }
    if (isDurableStoreConfigured()) {
      await durableSet(MEDIA_KEY, blob);
    }
    await blobSetMediaIndex(blob);
  });
}

export function readSiteContent(): SiteContentData {
  if (!contentCache) contentCache = loadContentDisk();
  return contentCache;
}

export function getPublicSiteContent(): PublicSiteContent {
  const data = readSiteContent();
  // Relay playlist: only complete, enabled ads play — order preserved.
  const playable = data.phoneAds.ads.filter(
    (a) =>
      a.enabled &&
      a.video &&
      a.poster &&
      a.href &&
      a.href !== "#"
  );
  return {
    updatedAt: data.updatedAt,
    phoneAds: {
      rotateOnEnd: data.phoneAds.rotateOnEnd !== false,
      ads: playable.length ? playable : DEFAULT_PHONE_ADS.map((a) => ({ ...a })),
    },
    hero: data.hero,
    logos: data.logos,
    header: data.header,
    footer: data.footer,
  };
}

export function saveSiteContent(patch: Partial<SiteContentData>): SiteContentData {
  const current = structuredClone(readSiteContent());
  const next = normalizeContent({
    ...current,
    ...patch,
    phoneAds: patch.phoneAds ?? current.phoneAds,
    hero: patch.hero ? { ...current.hero, ...patch.hero } : current.hero,
    logos: patch.logos ? { ...current.logos, ...patch.logos } : current.logos,
    header: patch.header ? { ...current.header, ...patch.header } : current.header,
    footer: patch.footer ? { ...current.footer, ...patch.footer } : current.footer,
    updatedAt: new Date().toISOString(),
    version: 1,
  });
  persistContent(next);
  return next;
}

export function saveStoredMedia(item: StoredMediaObject): void {
  const data = mediaCache || loadMediaDisk();
  data.items[item.id] = item;
  persistMedia(data);
}

export function getStoredMedia(id: string): StoredMediaObject | null {
  const data = mediaCache || loadMediaDisk();
  return data.items[id] || null;
}

export function listStoredMedia(): StoredMediaObject[] {
  const data = mediaCache || loadMediaDisk();
  return Object.values(data.items).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function flushSiteContent(): Promise<void> {
  await writeChain;
}

export function isSiteContentDurable(): boolean {
  return isDurableStoreConfigured() || isBlobPersistConfigured();
}
