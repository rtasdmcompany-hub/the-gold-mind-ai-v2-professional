import { maskFingerprint, nowIso, sha256 } from "./crypto";
import { appendAudit, mutateStore, readStore } from "./store";
import type { DevicePublicDto, DeviceRecord } from "./types";

export function toPublicDevice(d: DeviceRecord): DevicePublicDto {
  return {
    id: d.id,
    licenseId: d.licenseId,
    name: d.name,
    status: d.status,
    activationDate: d.activationDate,
    lastActiveAt: d.lastActiveAt,
    transferRequestedAt: d.transferRequestedAt,
    fingerprintMasked: maskFingerprint(d.fingerprintHash),
  };
}

export function listDevicesForCustomer(email: string): DevicePublicDto[] {
  const e = email.trim().toLowerCase();
  return readStore()
    .devices.filter((d) => d.customerEmail === e)
    .map(toPublicDevice);
}

export function renameDevice(deviceId: string, email: string, name: string): DevicePublicDto | null {
  const e = email.trim().toLowerCase();
  let result: DevicePublicDto | null = null;
  mutateStore((data) => {
    const d = data.devices.find((x) => x.id === deviceId && x.customerEmail === e);
    if (!d) return;
    d.name = name.trim().slice(0, 80) || d.name;
    appendAudit(data, {
      actorEmail: e,
      action: "device.renamed",
      entityType: "device",
      entityId: d.id,
      detail: `Renamed to ${d.name}`,
    });
    result = toPublicDevice(d);
  });
  return result;
}

export function deactivateDevice(deviceId: string, email: string): boolean {
  const e = email.trim().toLowerCase();
  let ok = false;
  mutateStore((data) => {
    const d = data.devices.find((x) => x.id === deviceId && x.customerEmail === e);
    if (!d) return;
    d.status = "inactive";
    d.lastActiveAt = nowIso();
    appendAudit(data, {
      actorEmail: e,
      action: "device.deactivated",
      entityType: "device",
      entityId: d.id,
      detail: "Device deactivated by customer",
    });
    ok = true;
  });
  return ok;
}

export function requestDeviceTransfer(deviceId: string, email: string): boolean {
  const e = email.trim().toLowerCase();
  let ok = false;
  mutateStore((data) => {
    const d = data.devices.find((x) => x.id === deviceId && x.customerEmail === e);
    if (!d || d.status !== "active") return;
    d.status = "pending_transfer";
    d.transferRequestedAt = nowIso();
    appendAudit(data, {
      actorEmail: e,
      action: "device.transfer_requested",
      entityType: "device",
      entityId: d.id,
      detail: "Transfer requested — deactivate source before activating destination",
    });
    ok = true;
  });
  return ok;
}

export function listAllDevicesAdmin(): DeviceRecord[] {
  return readStore().devices;
}

export function fingerprintFromComponents(parts: {
  userAgent?: string;
  language?: string;
  timezone?: string;
  screen?: string;
}): string {
  return sha256(
    [parts.userAgent || "", parts.language || "", parts.timezone || "", parts.screen || ""].join("|")
  );
}
