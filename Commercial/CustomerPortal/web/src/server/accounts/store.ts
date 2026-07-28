import { createHash, randomBytes, scryptSync, timingSafeEqual } from "crypto";
import fs from "fs";
import path from "path";
import {
  cacheGet,
  cacheSet,
  durableGet,
  durableSet,
  isDurableStoreConfigured,
} from "@/server/cloud/cache";
import { commercialDataRoot } from "@/server/cloud/data-root";
import { decryptJson, encryptJson } from "@/server/licensing/crypto";

export type AccountRecord = {
  id: string;
  email: string;
  name: string;
  passwordHash: string | null;
  emailVerifiedAt: string | null;
  verifyTokenHash: string | null;
  verifyTokenExpiresAt: string | null;
  provider: "credentials" | "google" | "both";
  /** Email alerts when trades close (profit or loss). Default ON when unset. */
  tradeAlertsEnabled?: boolean;
  createdAt: string;
  updatedAt: string;
};

type AccountStore = { version: 1; accounts: AccountRecord[] };

const STORE_FILE = "accounts.enc";
const DURABLE_KEY = "tgm:accounts:store:v1";
const CACHE_TTL = 60 * 60 * 24 * 30;

let memoryCache: AccountStore | null = null;
let writeChain: Promise<void> = Promise.resolve();
let loadPromise: Promise<void> | null = null;

function storePath(): string {
  return path.join(commercialDataRoot("accounts"), STORE_FILE);
}

function emptyStore(): AccountStore {
  return { version: 1, accounts: [] };
}

function loadRawFromDisk(): AccountStore {
  const p = storePath();
  if (!fs.existsSync(p)) return emptyStore();
  try {
    const blob = fs.readFileSync(p, "utf8");
    const data = decryptJson<AccountStore>(blob);
    if (!data?.accounts) return emptyStore();
    return data;
  } catch {
    return emptyStore();
  }
}

/** Prefer durable Redis/Blob on Vercel, then encrypted disk, then memory. */
async function ensureStoreLoaded(): Promise<void> {
  if (memoryCache) return;
  if (!loadPromise) {
    loadPromise = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(DURABLE_KEY);
          if (remote) {
            memoryCache = decryptJson<AccountStore>(remote);
            return;
          }
        } catch {
          /* fall through */
        }
      }
      memoryCache = loadRawFromDisk();
      if (isDurableStoreConfigured() && memoryCache.accounts.length > 0) {
        try {
          await durableSet(DURABLE_KEY, encryptJson(memoryCache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      if (!memoryCache) loadPromise = null;
    });
  }
  await loadPromise;
  if (!memoryCache) memoryCache = emptyStore();
}

function readStore(): AccountStore {
  if (!memoryCache) {
    memoryCache = loadRawFromDisk();
  }
  return memoryCache;
}

function writeStore(data: AccountStore): void {
  memoryCache = data;
  const blob = encryptJson(data);
  writeChain = writeChain.then(async () => {
    try {
      const dir = path.dirname(storePath());
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(storePath(), blob, "utf8");
    } catch {
      /* serverless may only have durable store */
    }
    if (isDurableStoreConfigured()) {
      try {
        await durableSet(DURABLE_KEY, blob);
      } catch (e) {
        console.warn("[accounts] durableSet failed", e instanceof Error ? e.message : e);
      }
    }
  });
}

function cacheKey(email: string): string {
  return `tgm:account:${email.toLowerCase()}`;
}

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 64).toString("hex");
  return `${salt}:${hash}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [salt, hash] = stored.split(":");
  if (!salt || !hash) return false;
  try {
    const next = scryptSync(password, salt, 64);
    const prev = Buffer.from(hash, "hex");
    if (prev.length !== next.length) return false;
    return timingSafeEqual(prev, next);
  } catch {
    return false;
  }
}

export function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export async function getAccountByEmail(email: string): Promise<AccountRecord | null> {
  const key = email.toLowerCase().trim();
  if (!key) return null;
  await ensureStoreLoaded();
  const cached = await cacheGet(cacheKey(key));
  if (cached) {
    try {
      return JSON.parse(cached) as AccountRecord;
    } catch {
      /* fall through */
    }
  }
  const found = readStore().accounts.find((a) => a.email === key) || null;
  if (found) await cacheSet(cacheKey(key), JSON.stringify(found), CACHE_TTL);
  return found;
}

export async function saveAccount(account: AccountRecord): Promise<AccountRecord> {
  await ensureStoreLoaded();
  const data = readStore();
  const idx = data.accounts.findIndex((a) => a.email === account.email);
  if (idx >= 0) data.accounts[idx] = account;
  else data.accounts.unshift(account);
  writeStore(data);
  await writeChain;
  await cacheSet(cacheKey(account.email), JSON.stringify(account), CACHE_TTL);
  return account;
}

export function newAccountId(): string {
  return `acc_${randomBytes(8).toString("hex")}`;
}

export function newVerifyToken(): string {
  return randomBytes(32).toString("hex");
}
