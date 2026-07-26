import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type { BillingStoreData } from "./types";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.BILLING_STORE_SECRET ||
    process.env.LICENSE_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-billing-store";
  return createHash("sha256").update(raw).digest();
}

function encryptJson(obj: unknown): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGO, masterKey(), iv);
  const plaintext = Buffer.from(JSON.stringify(obj), "utf8");
  const enc = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString("base64");
}

function decryptJson<T>(blob: string): T {
  const buf = Buffer.from(blob, "base64");
  const iv = buf.subarray(0, 12);
  const tag = buf.subarray(12, 28);
  const data = buf.subarray(28);
  const decipher = createDecipheriv(ALGO, masterKey(), iv);
  decipher.setAuthTag(tag);
  const dec = Buffer.concat([decipher.update(data), decipher.final()]);
  return JSON.parse(dec.toString("utf8")) as T;
}

const EMPTY: BillingStoreData = {
  version: 1,
  edition: "Professional_Website",
  invoices: [],
  payments: [],
  subscriptions: [],
  processedWebhooks: [],
  webhookAudits: [],
  emails: [],
};

function dataDir(): string {
  const dir = process.env.BILLING_DATA_DIR || path.join(process.cwd(), ".data", "billing");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function storePath(): string {
  return path.join(dataDir(), "billing.enc");
}

let cache: BillingStoreData | null = null;

function normalizeStore(data: BillingStoreData): BillingStoreData {
  if (!Array.isArray(data.webhookAudits)) data.webhookAudits = [];
  if (!Array.isArray(data.processedWebhooks)) data.processedWebhooks = [];
  if (!Array.isArray(data.invoices)) data.invoices = [];
  if (!Array.isArray(data.payments)) data.payments = [];
  if (!Array.isArray(data.subscriptions)) data.subscriptions = [];
  if (!Array.isArray(data.emails)) data.emails = [];
  return data;
}

export function readBillingStore(): BillingStoreData {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = normalizeStore(decryptJson<BillingStoreData>(fs.readFileSync(p, "utf8")));
    return cache!;
  } catch {
    throw new Error("BILLING_STORE_DECRYPT_FAIL");
  }
}

export function writeBillingStore(data: BillingStoreData): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function mutateBilling(mutator: (data: BillingStoreData) => void): BillingStoreData {
  const data = structuredClone(readBillingStore());
  mutator(data);
  // Cap collections
  if (data.processedWebhooks.length > 5000) data.processedWebhooks.length = 5000;
  if (data.webhookAudits.length > 5000) data.webhookAudits.length = 5000;
  if (data.emails.length > 2000) data.emails.length = 2000;
  writeBillingStore(normalizeStore(data));
  return data;
}
