/**
 * Encrypted API platform store — keys, tokens, webhooks, usage.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type {
  ApiErrorEvent,
  ApiKeyRecord,
  ApiUsageEvent,
  OAuthTokenRecord,
  WebhookDelivery,
  WebhookEndpoint,
} from "./types";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.API_PLATFORM_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-api-platform";
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

export interface ApiPlatformStore {
  version: 1;
  keys: ApiKeyRecord[];
  tokens: OAuthTokenRecord[];
  webhooks: WebhookEndpoint[];
  deliveries: WebhookDelivery[];
  usage: ApiUsageEvent[];
  errors: ApiErrorEvent[];
  rateBuckets: Record<string, { count: number; windowStart: number }>;
}

const EMPTY: ApiPlatformStore = {
  version: 1,
  keys: [],
  tokens: [],
  webhooks: [],
  deliveries: [],
  usage: [],
  errors: [],
  rateBuckets: {},
};

let cache: ApiPlatformStore | null = null;

function storePath(): string {
  const dir = path.join(process.cwd(), ".data", "api-platform");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "platform.enc");
}

export function readApiStore(): ApiPlatformStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<ApiPlatformStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  for (const k of Object.keys(EMPTY) as (keyof ApiPlatformStore)[]) {
    if (cache[k] === undefined) (cache as unknown as Record<string, unknown>)[k] = structuredClone(EMPTY[k]);
  }
  return cache;
}

export function writeApiStore(data: ApiPlatformStore): void {
  if (data.usage.length > 2000) data.usage = data.usage.slice(0, 2000);
  if (data.errors.length > 1000) data.errors = data.errors.slice(0, 1000);
  if (data.deliveries.length > 1000) data.deliveries = data.deliveries.slice(0, 1000);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function newApiId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export function hashSecret(secret: string): string {
  return createHash("sha256").update(secret).digest("hex");
}

export function issueSecret(prefix: string): string {
  return `${prefix}_${randomBytes(24).toString("base64url")}`;
}
