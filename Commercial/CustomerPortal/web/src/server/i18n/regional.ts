/**
 * Regional configuration store — language, timezone, formats, legal/support keys.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type { RegionalSettings } from "./types";
import { DEFAULT_REGIONAL, applyRegional } from "./runtime";

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

interface RegionalStore {
  version: 1;
  default: RegionalSettings;
  byRegion: Record<string, RegionalSettings>;
}

function seedStore(): RegionalStore {
  return {
    version: 1,
    default: { ...DEFAULT_REGIONAL },
    byRegion: {
      US: {
        ...DEFAULT_REGIONAL,
        language: "en",
        timezone: "America/New_York",
        currency: "USD",
        measurement: "imperial",
      },
      PK: {
        ...DEFAULT_REGIONAL,
        language: "ur",
        timezone: "Asia/Karachi",
        currency: "PKR",
        measurement: "metric",
      },
      AE: {
        ...DEFAULT_REGIONAL,
        language: "ar",
        timezone: "Asia/Dubai",
        currency: "AED",
        measurement: "metric",
      },
      FR: {
        ...DEFAULT_REGIONAL,
        language: "fr",
        timezone: "Europe/Paris",
        currency: "EUR",
        measurement: "metric",
      },
      DE: {
        ...DEFAULT_REGIONAL,
        language: "de",
        timezone: "Europe/Berlin",
        currency: "EUR",
        measurement: "metric",
      },
      ES: {
        ...DEFAULT_REGIONAL,
        language: "es",
        timezone: "Europe/Madrid",
        currency: "EUR",
        measurement: "metric",
      },
      TR: {
        ...DEFAULT_REGIONAL,
        language: "tr",
        timezone: "Europe/Istanbul",
        currency: "TRY",
        measurement: "metric",
      },
    },
  };
}

let cache: RegionalStore | null = null;

function storePath(): string {
  const dir = path.join(process.cwd(), ".data", "i18n");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "regional.enc");
}

function read(): RegionalStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = seedStore();
    return cache;
  }
  try {
    cache = decryptJson<RegionalStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = seedStore();
  }
  if (!cache.default) cache.default = { ...DEFAULT_REGIONAL };
  if (!cache.byRegion) cache.byRegion = seedStore().byRegion;
  return cache;
}

function write(data: RegionalStore): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function getDefaultRegional(): RegionalSettings {
  return { ...read().default };
}

export function getRegionalForCode(regionCode: string): RegionalSettings {
  const store = read();
  return { ...(store.byRegion[regionCode.toUpperCase()] || store.default) };
}

export function listRegionalProfiles(): {
  code: string;
  settings: RegionalSettings;
  preview: ReturnType<typeof applyRegional>;
}[] {
  const store = read();
  return Object.entries(store.byRegion).map(([code, settings]) => ({
    code,
    settings,
    preview: applyRegional(settings),
  }));
}

export function updateRegionalProfile(
  regionCode: string,
  patch: Partial<RegionalSettings>
): RegionalSettings {
  const store = read();
  const key = regionCode.toUpperCase();
  const current = store.byRegion[key] || { ...store.default };
  const next = { ...current, ...patch };
  store.byRegion[key] = next;
  write(store);
  return next;
}

export function setDefaultRegional(settings: RegionalSettings): RegionalSettings {
  const store = read();
  store.default = { ...settings };
  write(store);
  return store.default;
}
