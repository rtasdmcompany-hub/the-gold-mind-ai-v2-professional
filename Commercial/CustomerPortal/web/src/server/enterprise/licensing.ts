/**
 * Team / seat licensing — config-enforced, Core-independent.
 */
import type { LicensePool, SeatLicense } from "./types";
import {
  assertOrgIsolation,
  mutateEnterpriseStore,
  newId,
  readEnterpriseStore,
} from "./store";

function licenseAudit(
  orgId: string,
  poolId: string,
  actor: string,
  action: import("./types").LicenseAuditEntry["action"],
  detail: string,
  seatId?: string
) {
  mutateEnterpriseStore((d) => {
    d.licenseAudit.unshift({
      id: newId("laud"),
      orgId,
      poolId,
      seatId,
      at: new Date().toISOString(),
      actor,
      action,
      detail,
    });
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: `license_${action}`,
      detail,
      immutable: true,
    });
  });
}

export function createLicensePool(input: {
  orgId: string;
  name: string;
  planCode: string;
  seats: number;
  subscriptionId?: string;
  actor: string;
}): LicensePool {
  const store = readEnterpriseStore();
  if (input.seats > store.config.licensing.maxSeatsPerPool) throw new Error("SEAT_LIMIT_POLICY");
  const org = store.organizations.find((o) => o.id === input.orgId);
  if (!org) throw new Error("ORG_NOT_FOUND");
  if (input.seats > org.settings.seatLimit) throw new Error("ORG_SEAT_LIMIT");

  let pool: LicensePool | null = null;
  mutateEnterpriseStore((d) => {
    pool = {
      id: newId("pool"),
      orgId: input.orgId,
      name: input.name,
      planCode: input.planCode,
      totalSeats: input.seats,
      subscriptionId: input.subscriptionId,
      status: "active",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    d.pools.unshift(pool);
    for (let i = 0; i < input.seats; i++) {
      d.seats.unshift({
        id: newId("seat"),
        orgId: input.orgId,
        poolId: pool.id,
        seatIndex: i + 1,
        status: "available",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
    }
  });
  licenseAudit(input.orgId, pool!.id, input.actor, "pool_create", `${input.seats} seats`);
  return pool!;
}

export function assignSeat(input: {
  orgId: string;
  seatId: string;
  memberId: string;
  actor: string;
}): SeatLicense {
  let seat: SeatLicense | null = null;
  mutateEnterpriseStore((d) => {
    const s = d.seats.find((x) => x.id === input.seatId);
    const m = d.members.find((x) => x.id === input.memberId);
    if (!s || !m) throw new Error("SEAT_OR_MEMBER_NOT_FOUND");
    assertOrgIsolation(input.orgId, s.orgId);
    assertOrgIsolation(input.orgId, m.orgId);
    if (s.status !== "available") throw new Error("SEAT_NOT_AVAILABLE");
    s.assignedMemberId = m.id;
    s.assignedEmail = m.email;
    s.status = "assigned";
    s.updatedAt = new Date().toISOString();
    seat = s;
    d.licenseAudit.unshift({
      id: newId("laud"),
      orgId: input.orgId,
      poolId: s.poolId,
      seatId: s.id,
      at: new Date().toISOString(),
      actor: input.actor,
      action: "assign",
      detail: m.email,
    });
    d.audit.unshift({
      id: newId("eaud"),
      orgId: input.orgId,
      at: new Date().toISOString(),
      actor: input.actor,
      action: "license_assign",
      detail: `${s.id}→${m.email}`,
      immutable: true,
    });
  });
  return seat!;
}

export function revokeSeat(orgId: string, seatId: string, actor: string): void {
  mutateEnterpriseStore((d) => {
    const s = d.seats.find((x) => x.id === seatId);
    if (!s) throw new Error("SEAT_NOT_FOUND");
    assertOrgIsolation(orgId, s.orgId);
    const prev = s.assignedEmail;
    s.assignedMemberId = undefined;
    s.assignedEmail = undefined;
    s.status = "revoked";
    s.updatedAt = new Date().toISOString();
    d.licenseAudit.unshift({
      id: newId("laud"),
      orgId,
      poolId: s.poolId,
      seatId: s.id,
      at: new Date().toISOString(),
      actor,
      action: "revoke",
      detail: String(prev || ""),
    });
  });
}

export function transferSeat(input: {
  orgId: string;
  seatId: string;
  toMemberId: string;
  actor: string;
}): void {
  const store = readEnterpriseStore();
  const org = store.organizations.find((o) => o.id === input.orgId);
  if (!org?.settings.allowLicenseTransfer || !store.config.licensing.allowTransfer) {
    throw new Error("TRANSFER_DISABLED_BY_POLICY");
  }
  mutateEnterpriseStore((d) => {
    const s = d.seats.find((x) => x.id === input.seatId);
    const m = d.members.find((x) => x.id === input.toMemberId);
    if (!s || !m) throw new Error("SEAT_OR_MEMBER_NOT_FOUND");
    assertOrgIsolation(input.orgId, s.orgId);
    assertOrgIsolation(input.orgId, m.orgId);
    const from = s.assignedEmail;
    s.assignedMemberId = m.id;
    s.assignedEmail = m.email;
    s.status = "assigned";
    s.updatedAt = new Date().toISOString();
    d.licenseAudit.unshift({
      id: newId("laud"),
      orgId: input.orgId,
      poolId: s.poolId,
      seatId: s.id,
      at: new Date().toISOString(),
      actor: input.actor,
      action: "transfer",
      detail: `${from}→${m.email}`,
    });
  });
}

export function bulkActivate(orgId: string, poolId: string, memberIds: string[], actor: string): number {
  const store = readEnterpriseStore();
  if (!store.config.licensing.allowBulkOps) throw new Error("BULK_DISABLED_BY_POLICY");
  const available = store.seats.filter(
    (s) => s.orgId === orgId && s.poolId === poolId && (s.status === "available" || s.status === "revoked")
  );
  let n = 0;
  for (const memberId of memberIds) {
    const seat = available[n];
    if (!seat) break;
    // reset revoked to available then assign
    mutateEnterpriseStore((d) => {
      const s = d.seats.find((x) => x.id === seat.id)!;
      s.status = "available";
    });
    assignSeat({ orgId, seatId: seat.id, memberId, actor });
    n += 1;
  }
  licenseAudit(orgId, poolId, actor, "bulk_activate", `${n} seats`);
  return n;
}

export function bulkDeactivate(orgId: string, seatIds: string[], actor: string): number {
  const store = readEnterpriseStore();
  if (!store.config.licensing.allowBulkOps) throw new Error("BULK_DISABLED_BY_POLICY");
  let n = 0;
  for (const seatId of seatIds) {
    const s = store.seats.find((x) => x.id === seatId && x.orgId === orgId);
    if (!s) continue;
    mutateEnterpriseStore((d) => {
      const seat = d.seats.find((x) => x.id === seatId)!;
      seat.assignedMemberId = undefined;
      seat.assignedEmail = undefined;
      seat.status = "disabled";
      seat.updatedAt = new Date().toISOString();
    });
    n += 1;
  }
  if (seatIds[0]) {
    const poolId = store.seats.find((s) => s.id === seatIds[0])?.poolId || "unknown";
    licenseAudit(orgId, poolId, actor, "bulk_deactivate", `${n} seats`);
  }
  return n;
}

export function getPoolUtilization(orgId: string, poolId: string) {
  const seats = readEnterpriseStore().seats.filter((s) => s.orgId === orgId && s.poolId === poolId);
  const assigned = seats.filter((s) => s.status === "assigned").length;
  return {
    total: seats.length,
    assigned,
    available: seats.filter((s) => s.status === "available").length,
    utilizationPct: seats.length === 0 ? 0 : Math.round((assigned / seats.length) * 1000) / 10,
  };
}

export function listLicenseAudit(orgId: string, limit = 50) {
  return readEnterpriseStore()
    .licenseAudit.filter((a) => a.orgId === orgId)
    .slice(0, limit);
}
