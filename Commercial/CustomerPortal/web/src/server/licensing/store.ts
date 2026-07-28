import fs from "fs";
import {
  assertDurableStoreForLicensing,
  durableGet,
  durableSet,
  isDurableStoreConfigured,
} from "@/server/cloud/cache";
import {
  decryptJson,
  encryptJson,
  hmacSha256,
  nowIso,
  safeEqualHex,
  storePath,
} from "./crypto";
import type { AuditEvent, LicenseRecord, LicenseStoreData } from "./types";

const EMPTY: LicenseStoreData = {
  version: 1,
  licenses: [],
  devices: [],
  subscriptions: [],
  audit: [],
};

/** Durable Redis key — survives Vercel /tmp wipes when UPSTASH_* is set. */
const DURABLE_KEY = "tgm:licensing:store:v1";

let memoryCache: LicenseStoreData | null = null;
let writeChain: Promise<void> = Promise.resolve();
let loadPromise: Promise<void> | null = null;

export function licenseIntegrityPayload(lic: Omit<LicenseRecord, "integrityMac">): string {
  return [
    lic.id,
    lic.customerEmail,
    lic.keyHash,
    lic.keyPrefix,
    lic.keyLast4,
    lic.type,
    lic.status,
    lic.seatsMax,
    lic.expiresAt ?? "",
    lic.graceEndsAt ?? "",
  ].join("|");
}

export function computeIntegrityMac(lic: Omit<LicenseRecord, "integrityMac">): string {
  return hmacSha256(licenseIntegrityPayload(lic));
}

export function verifyIntegrity(lic: LicenseRecord): boolean {
  const { integrityMac, ...rest } = lic;
  return safeEqualHex(hmacSha256(licenseIntegrityPayload(rest)), integrityMac);
}

function loadRawFromDisk(): LicenseStoreData {
  const p = storePath();
  if (!fs.existsSync(p)) return structuredClone(EMPTY);
  try {
    const blob = fs.readFileSync(p, "utf8");
    return decryptJson<LicenseStoreData>(blob);
  } catch {
    throw new Error("LICENSE_STORE_TAMPER_OR_DECRYPT_FAIL");
  }
}

/**
 * Load licensing store into memory.
 * Prefer Upstash durable blob (production), then local/encrypted file.
 * Call this at the start of every portal/API request that reads licenses.
 */
export async function ensureStoreLoaded(): Promise<void> {
  if (memoryCache) return;
  if (!loadPromise) {
    loadPromise = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(DURABLE_KEY);
          if (remote) {
            memoryCache = decryptJson<LicenseStoreData>(remote);
            return;
          }
        } catch {
          /* fall through to disk */
        }
      }
      memoryCache = loadRawFromDisk();
      if (isDurableStoreConfigured() && memoryCache.licenses.length > 0) {
        try {
          await durableSet(DURABLE_KEY, encryptJson(memoryCache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      /* keep memoryCache; allow retry only if still null */
      if (!memoryCache) loadPromise = null;
    });
  }
  await loadPromise;
  if (!memoryCache) memoryCache = structuredClone(EMPTY);
}

export function readStore(): LicenseStoreData {
  if (!memoryCache) {
    memoryCache = loadRawFromDisk();
  }
  return memoryCache;
}

export function writeStore(data: LicenseStoreData): void {
  assertDurableStoreForLicensing();
  memoryCache = data;
  const blob = encryptJson(data);
  writeChain = writeChain.then(async () => {
    try {
      fs.writeFileSync(storePath(), blob, "utf8");
    } catch {
      /* serverless may only have durable store */
    }
    if (isDurableStoreConfigured()) {
      await durableSet(DURABLE_KEY, blob);
      return;
    }
    // Local/dev only — file write above is enough. Production is blocked by assertDurableStoreForLicensing.
  });
}

/** Confirm the last write finished (Redis + disk). Call after create/activate before returning to installer. */
export async function flushStoreVerified(): Promise<void> {
  await writeChain;
  if (isDurableStoreConfigured()) {
    const remote = await durableGet(DURABLE_KEY);
    if (!remote) {
      throw new Error("DURABLE_STORE_VERIFY_FAILED: license write did not persist to Redis");
    }
  }
}

export async function flushStore(): Promise<void> {
  await writeChain;
}

export function appendAudit(
  data: LicenseStoreData,
  event: Omit<AuditEvent, "id" | "at"> & { at?: string }
): void {
  data.audit.unshift({
    id: `aud_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    at: event.at ?? nowIso(),
    actorEmail: event.actorEmail,
    action: event.action,
    entityType: event.entityType,
    entityId: event.entityId,
    detail: event.detail,
    meta: event.meta,
  });
  // Cap audit trail
  if (data.audit.length > 2000) data.audit.length = 2000;
}

export function mutateStore(mutator: (data: LicenseStoreData) => void): LicenseStoreData {
  const data = structuredClone(readStore());
  mutator(data);
  writeStore(data);
  return data;
}
