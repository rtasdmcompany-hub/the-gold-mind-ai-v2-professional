/**
 * Translation management — status dashboard, review/approval workflow.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import { commercialDataRoot } from "@/server/cloud/data-root";
import type { LocaleCode, TranslationReviewItem, TranslationStatus } from "./types";
import { masterKeys, getLocalePack } from "./packs";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.I18N_STORE_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-i18n-store";
  return createHash("sha256").update(raw).digest();
}

function encryptJson(obj: unknown): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGO, masterKey(), iv);
  const enc = Buffer.concat([cipher.update(Buffer.from(JSON.stringify(obj), "utf8")), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString("base64");
}

function decryptJson<T>(blob: string): T {
  const buf = Buffer.from(blob, "base64");
  const decipher = createDecipheriv(ALGO, masterKey(), buf.subarray(0, 12));
  decipher.setAuthTag(buf.subarray(12, 28));
  const dec = Buffer.concat([decipher.update(buf.subarray(28)), decipher.final()]);
  return JSON.parse(dec.toString("utf8")) as T;
}

interface WorkflowStore {
  version: 1;
  reviews: TranslationReviewItem[];
}

const EMPTY: WorkflowStore = { version: 1, reviews: [] };
let cache: WorkflowStore | null = null;

function storePath(): string {
  const dir = commercialDataRoot("i18n");
  return path.join(dir, "workflow.enc");
}

function read(): WorkflowStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<WorkflowStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  if (!Array.isArray(cache.reviews)) cache.reviews = [];
  return cache;
}

function write(data: WorkflowStore): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function getTranslationStatusDashboard() {
  const keys = masterKeys();
  const locales = ["en", "ur", "ar", "fr", "de", "es", "tr"];
  const rows = locales.map((code) => {
    const pack = getLocalePack(code);
    const translated = keys.filter((k) => !!pack.catalog[k]).length;
    const missing = keys.length - translated;
    const reviews = read().reviews.filter((r) => r.locale === code);
    return {
      locale: code,
      version: pack.manifest.version,
      translated,
      missing,
      percent: Math.round((translated / keys.length) * 1000) / 10,
      inReview: reviews.filter((r) => r.status === "in_review").length,
      approved: reviews.filter((r) => r.status === "approved" || r.status === "published").length,
      status: missing === 0 ? ("published" as TranslationStatus) : ("draft" as TranslationStatus),
    };
  });
  return { rows, masterKeys: keys.length, reviews: read().reviews.slice(0, 50), at: new Date().toISOString() };
}

export function submitTranslationForReview(input: {
  locale: LocaleCode;
  key: string;
  proposed: string;
  actor: string;
}): TranslationReviewItem {
  const en = getLocalePack("en");
  const item: TranslationReviewItem = {
    id: `tr_${Date.now().toString(36)}_${randomBytes(2).toString("hex")}`,
    locale: input.locale,
    key: input.key,
    source: en.catalog[input.key] || input.key,
    proposed: input.proposed,
    status: "in_review",
    updatedAt: new Date().toISOString(),
  };
  const store = read();
  store.reviews.unshift(item);
  write(store);
  return item;
}

export function approveTranslation(id: string, reviewer: string): TranslationReviewItem {
  const store = read();
  const item = store.reviews.find((r) => r.id === id);
  if (!item) throw new Error("REVIEW_NOT_FOUND");
  item.status = "approved";
  item.reviewer = reviewer;
  item.updatedAt = new Date().toISOString();
  write(store);
  return item;
}

export function missingTranslationReport(locale: LocaleCode) {
  const keys = masterKeys();
  const pack = getLocalePack(locale);
  return {
    locale,
    missing: keys.filter((k) => !pack.catalog[k]),
    at: new Date().toISOString(),
  };
}

export function translationRepositoryInfo() {
  return {
    path: path.join(process.cwd(), "locales"),
    versionControl: "Each pack has independent version in manifest.json; messages.json is the translation unit",
    note: "Future languages: add locales/{code}/manifest.json + messages.json — no app code change",
  };
}
