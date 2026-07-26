import fs from "fs";
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

let memoryCache: LicenseStoreData | null = null;
let writeChain: Promise<void> = Promise.resolve();

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

function loadRaw(): LicenseStoreData {
  const p = storePath();
  if (!fs.existsSync(p)) return structuredClone(EMPTY);
  try {
    const blob = fs.readFileSync(p, "utf8");
    return decryptJson<LicenseStoreData>(blob);
  } catch {
    throw new Error("LICENSE_STORE_TAMPER_OR_DECRYPT_FAIL");
  }
}

export function readStore(): LicenseStoreData {
  if (!memoryCache) {
    memoryCache = loadRaw();
  }
  return memoryCache;
}

export function writeStore(data: LicenseStoreData): void {
  memoryCache = data;
  writeChain = writeChain.then(() => {
    const blob = encryptJson(data);
    fs.writeFileSync(storePath(), blob, "utf8");
  });
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
