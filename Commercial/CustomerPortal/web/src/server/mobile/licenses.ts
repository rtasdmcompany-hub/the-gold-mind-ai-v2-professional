/**
 * Mobile license management — view, transfer, activate/deactivate devices.
 * Delegates to commercial licensing services — never touches Core.
 * Survives LICENSE_STORE decrypt mismatches in CLI (empty fallback).
 */
import {
  listLicensesForCustomer,
  activateLicense,
  type ActivateResult,
} from "@/server/licensing/license-service";
import {
  deactivateDevice,
  listDevicesForCustomer,
  requestDeviceTransfer,
  renameDevice,
} from "@/server/licensing/device-service";
import type { DevicePublicDto, LicensePublicDto } from "@/server/licensing/types";
import { newMobileId, readMobileStore, writeMobileStore } from "./store";

export interface ActivationHistoryEntry {
  id: string;
  customerEmail: string;
  licenseId: string;
  action: "activate" | "deactivate" | "transfer" | "view";
  deviceId?: string;
  at: string;
  detail: string;
}

const historyMem: ActivationHistoryEntry[] = [];

function record(entry: Omit<ActivationHistoryEntry, "id" | "at">) {
  const row: ActivationHistoryEntry = {
    ...entry,
    id: newMobileId("act"),
    at: new Date().toISOString(),
  };
  historyMem.unshift(row);
  if (historyMem.length > 200) historyMem.length = 200;
  return row;
}

async function safeLicenses(email: string): Promise<LicensePublicDto[]> {
  try {
    return await listLicensesForCustomer(email);
  } catch {
    return [];
  }
}

function safeDevices(email: string): DevicePublicDto[] {
  try {
    return listDevicesForCustomer(email);
  } catch {
    return [];
  }
}

export async function mobileListLicenses(email: string) {
  const items = await safeLicenses(email);
  return {
    active: items.filter((l) => l.status === "active" || l.status === "grace"),
    history: items,
    at: new Date().toISOString(),
  };
}

export function mobileListLicenseDevices(email: string) {
  return safeDevices(email);
}

export function mobileDeactivateOldDevice(deviceId: string, email: string) {
  try {
    const ok = deactivateDevice(deviceId, email);
    if (ok) {
      record({
        customerEmail: email.toLowerCase(),
        licenseId: "n/a",
        action: "deactivate",
        deviceId,
        detail: "Device deactivated from Mobile Companion",
      });
    }
    return ok;
  } catch {
    return false;
  }
}

export function mobileTransferEligibleLicense(deviceId: string, email: string) {
  try {
    const ok = requestDeviceTransfer(deviceId, email);
    if (ok) {
      record({
        customerEmail: email.toLowerCase(),
        licenseId: "n/a",
        action: "transfer",
        deviceId,
        detail: "Transfer requested via Mobile Companion",
      });
    }
    return ok;
  } catch {
    return false;
  }
}

export async function mobileActivateOnNewDevice(input: {
  email: string;
  licenseKey: string;
  deviceName: string;
  fingerprint: string;
}): Promise<ActivateResult | { ok: false; error: string }> {
  try {
    const result = await activateLicense({
      plaintextKey: input.licenseKey,
      customerEmail: input.email,
      deviceName: input.deviceName,
      deviceFingerprint: input.fingerprint,
    });
    if (result.ok && result.license) {
      record({
        customerEmail: input.email.toLowerCase(),
        licenseId: result.license.id,
        action: "activate",
        deviceId: result.deviceId,
        detail: `Activated on ${input.deviceName}`,
      });
    }
    return result;
  } catch {
    return { ok: false, error: "LICENSE_STORE_UNAVAILABLE" };
  }
}

export function mobileRenameDevice(deviceId: string, email: string, name: string) {
  try {
    return renameDevice(deviceId, email, name);
  } catch {
    return null;
  }
}

export function mobileActivationHistory(email: string) {
  return historyMem.filter((h) => h.customerEmail === email.toLowerCase()).slice(0, 50);
}

export async function seedMobileLicenseDemo(email: string) {
  record({
    customerEmail: email.toLowerCase(),
    licenseId: "demo",
    action: "view",
    detail: "Dashboard license list viewed",
  });
  const store = readMobileStore();
  writeMobileStore(store);
  return await mobileListLicenses(email);
}