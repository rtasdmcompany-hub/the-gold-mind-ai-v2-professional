import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type { BillingStoreData } from "./types";
import { commercialDataRoot } from "@/server/cloud/data-root";
import {
  durableGet,
  durableSet,
  isDurableStoreConfigured,
  isDurableStoreRequired,
} from "@/server/cloud/cache";

const ALGO = "aes-256-gcm";
const DURABLE_KEY = "tgm:billing:store:v1";

function masterKey(): Buffer {
  const raw =
    process.env.BILLING_STORE_SECRET ||
    process.env.LICENSE_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    process.env.AUTH_SECRET ||
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
  const dir = process.env.BILLING_DATA_DIR || commercialDataRoot("billing");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function storePath(): string {
  return path.join(dataDir(), "billing.enc");
}

let cache: BillingStoreData | null = null;
let writeChain: Promise<void> = Promise.resolve();
let loadPromise: Promise<void> | null = null;

function normalizeStore(data: BillingStoreData): BillingStoreData {
  if (!Array.isArray(data.webhookAudits)) data.webhookAudits = [];
  if (!Array.isArray(data.processedWebhooks)) data.processedWebhooks = [];
  if (!Array.isArray(data.invoices)) data.invoices = [];
  if (!Array.isArray(data.payments)) data.payments = [];
  if (!Array.isArray(data.subscriptions)) data.subscriptions = [];
  if (!Array.isArray(data.emails)) data.emails = [];
  return data;
}

function loadRawFromDisk(): BillingStoreData {
  const p = storePath();
  if (!fs.existsSync(p)) return structuredClone(EMPTY);
  try {
    return normalizeStore(decryptJson<BillingStoreData>(fs.readFileSync(p, "utf8")));
  } catch {
    throw new Error("BILLING_STORE_DECRYPT_FAIL");
  }
}

export function assertDurableStoreForBilling(): void {
  if (isDurableStoreRequired() && !isDurableStoreConfigured()) {
    throw new Error(
      "DURABLE_STORE_REQUIRED: Set UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN so billing invoices/orders survive redeploys."
    );
  }
}

/** Prefer Upstash durable blob on serverless, then encrypted disk. */
export async function ensureBillingStoreLoaded(): Promise<void> {
  if (cache) return;
  if (!loadPromise) {
    loadPromise = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(DURABLE_KEY);
          if (remote) {
            cache = normalizeStore(decryptJson<BillingStoreData>(remote));
            return;
          }
        } catch {
          /* fall through */
        }
      }
      cache = loadRawFromDisk();
      if (isDurableStoreConfigured() && (cache.invoices.length > 0 || cache.payments.length > 0 || cache.subscriptions.length > 0)) {
        try {
          await durableSet(DURABLE_KEY, encryptJson(cache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      if (!cache) loadPromise = null;
    });
  }
  await loadPromise;
  if (!cache) cache = structuredClone(EMPTY);
}

export function readBillingStore(): BillingStoreData {
  if (cache) return cache;
  cache = loadRawFromDisk();
  return cache;
}

export function writeBillingStore(data: BillingStoreData): void {
  assertDurableStoreForBilling();
  cache = data;
  const blob = encryptJson(data);
  writeChain = writeChain.then(async () => {
    try {
      fs.writeFileSync(storePath(), blob, "utf8");
    } catch {
      /* serverless may only have durable store */
    }
    if (isDurableStoreConfigured()) {
      await durableSet(DURABLE_KEY, blob);
    }
  });
}

export async function flushBillingStore(): Promise<void> {
  await writeChain;
}

export function mutateBilling(mutator: (data: BillingStoreData) => void): BillingStoreData {
  const data = structuredClone(readBillingStore());
  mutator(data);
  if (data.processedWebhooks.length > 5000) data.processedWebhooks.length = 5000;
  if (data.webhookAudits.length > 5000) data.webhookAudits.length = 5000;
  if (data.emails.length > 2000) data.emails.length = 2000;
  writeBillingStore(normalizeStore(data));
  return data;
}

export function billingStoreDurability(): {
  durableConfigured: boolean;
  durableRequired: boolean;
  warning?: string;
} {
  const durableConfigured = isDurableStoreConfigured();
  const durableRequired = isDurableStoreRequired();
  return {
    durableConfigured,
    durableRequired,
    warning:
      durableRequired && !durableConfigured
        ? "Billing data will not survive serverless redeploys until Upstash Redis is configured."
        : !durableConfigured
          ? "Billing store is local-file only (dev). Configure UPSTASH_* for production durability."
          : undefined,
  };
}
