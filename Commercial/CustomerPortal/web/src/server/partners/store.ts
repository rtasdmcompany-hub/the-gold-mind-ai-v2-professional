/**
 * Partner / Affiliate encrypted store — commercial only, Core-isolated.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import { commercialDataRoot } from "@/server/cloud/data-root";
import type {
  AttributionEvent,
  CommissionLedgerEntry,
  PartnerApplication,
  PartnerCampaign,
  PartnerDispute,
  PartnerPayoutRequest,
  PartnerProfile,
  PartnerProgramConfig,
  ReferralClick,
} from "./types";
import { DEFAULT_PROGRAM_CONFIG } from "./config";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.PARTNER_STORE_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-partner-store";
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

export function partnerDataDir(subdir = ""): string {
  if (process.env.PARTNER_DATA_DIR) {
    const dir = subdir
      ? path.join(process.env.PARTNER_DATA_DIR, subdir)
      : process.env.PARTNER_DATA_DIR;
    try {
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      return dir;
    } catch {
      /* fall through */
    }
  }
  return subdir ? commercialDataRoot("partners", subdir) : commercialDataRoot("partners");
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export interface PartnerStoreData {
  version: 1;
  config: PartnerProgramConfig;
  partners: PartnerProfile[];
  applications: PartnerApplication[];
  clicks: ReferralClick[];
  attributions: AttributionEvent[];
  commissions: CommissionLedgerEntry[];
  payouts: PartnerPayoutRequest[];
  disputes: PartnerDispute[];
  campaigns: PartnerCampaign[];
  audit: { id: string; at: string; actor: string; action: string; detail: string }[];
}

const EMPTY: PartnerStoreData = {
  version: 1,
  config: DEFAULT_PROGRAM_CONFIG,
  partners: [],
  applications: [],
  clicks: [],
  attributions: [],
  commissions: [],
  payouts: [],
  disputes: [],
  campaigns: [],
  audit: [],
};

let cache: PartnerStoreData | null = null;

function storePath(): string {
  return path.join(partnerDataDir(), "partners.enc");
}

export function readPartnerStore(): PartnerStoreData {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    cache.config = structuredClone(DEFAULT_PROGRAM_CONFIG);
    return cache;
  }
  try {
    cache = decryptJson<PartnerStoreData>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
    cache.config = structuredClone(DEFAULT_PROGRAM_CONFIG);
  }
  if (!cache.config) cache.config = structuredClone(DEFAULT_PROGRAM_CONFIG);
  for (const key of [
    "partners",
    "applications",
    "clicks",
    "attributions",
    "commissions",
    "payouts",
    "disputes",
    "campaigns",
    "audit",
  ] as const) {
    if (!Array.isArray(cache[key])) (cache as PartnerStoreData)[key] = [] as never;
  }
  return cache;
}

export function writePartnerStore(data: PartnerStoreData): void {
  if (data.clicks.length > 20000) data.clicks = data.clicks.slice(0, 20000);
  if (data.audit.length > 5000) data.audit = data.audit.slice(0, 5000);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function mutatePartnerStore(fn: (data: PartnerStoreData) => void): PartnerStoreData {
  const data = readPartnerStore();
  fn(data);
  writePartnerStore(data);
  return data;
}

export function auditPartner(actor: string, action: string, detail: string): void {
  mutatePartnerStore((d) => {
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action,
      detail,
    });
  });
}

export function safeReadPartnerStore(): PartnerStoreData {
  try {
    return readPartnerStore();
  } catch {
    return structuredClone(EMPTY);
  }
}
