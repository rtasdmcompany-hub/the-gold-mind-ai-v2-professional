/**
 * Incident management store — commercial production only.
 */
import fs from "fs";
import path from "path";
import { writeAudit } from "@/server/cloud/audit";
import { decryptJson, encryptJson, launchDataDir, newId } from "./store-crypto";

export type IncidentSeverity = "critical" | "high" | "medium" | "low";
export type IncidentStatus = "open" | "investigating" | "mitigated" | "resolved" | "closed";

export interface IncidentRecord {
  id: string;
  title: string;
  severity: IncidentSeverity;
  status: IncidentStatus;
  summary: string;
  impact: string;
  affectedServices: string[];
  commander: string;
  owner?: string;
  environment?: string;
  rootCause?: string;
  resolution?: string;
  customerNotified: boolean;
  hotfixRequired: boolean;
  rollbackRequired: boolean;
  timeline: Array<{ at: string; by: string; note: string }>;
  createdAt: string;
  updatedAt: string;
  resolvedAt?: string;
}

interface IncidentStore {
  version: 1;
  incidents: IncidentRecord[];
}

const EMPTY: IncidentStore = { version: 1, incidents: [] };
let cache: IncidentStore | null = null;

function storePath(): string {
  return path.join(launchDataDir("incidents"), "incidents.enc");
}

function read(): IncidentStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<IncidentStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.incidents)) cache.incidents = [];
  return cache;
}

function write(data: IncidentStore): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export const SEVERITY_SLA: Record<
  IncidentSeverity,
  { ackMinutes: number; updateMinutes: number; targetResolveHours: number; escalateTo: string }
> = {
  critical: { ackMinutes: 15, updateMinutes: 30, targetResolveHours: 4, escalateTo: "Owner + CTO + Release" },
  high: { ackMinutes: 30, updateMinutes: 60, targetResolveHours: 24, escalateTo: "CTO + On-call" },
  medium: { ackMinutes: 240, updateMinutes: 480, targetResolveHours: 72, escalateTo: "Engineering lead" },
  low: { ackMinutes: 1440, updateMinutes: 2880, targetResolveHours: 168, escalateTo: "Backlog owner" },
};

export function listIncidents(filter?: { severity?: IncidentSeverity; status?: IncidentStatus; q?: string }) {
  let rows = [...read().incidents];
  if (filter?.severity) rows = rows.filter((i) => i.severity === filter.severity);
  if (filter?.status) rows = rows.filter((i) => i.status === filter.status);
  if (filter?.q) {
    const q = filter.q.toLowerCase();
    rows = rows.filter((i) => i.title.toLowerCase().includes(q) || i.id.includes(q) || i.summary.toLowerCase().includes(q));
  }
  return rows.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
}

export function getIncidentSummary() {
  const all = read().incidents;
  const open = all.filter((i) => i.status === "open" || i.status === "investigating" || i.status === "mitigated");
  return {
    total: all.length,
    open: open.length,
    criticalOpen: open.filter((i) => i.severity === "critical").length,
    highOpen: open.filter((i) => i.severity === "high").length,
    hotfixPending: open.filter((i) => i.hotfixRequired).length,
    rollbackPending: open.filter((i) => i.rollbackRequired).length,
  };
}

export function createIncident(input: {
  title: string;
  severity: IncidentSeverity;
  summary: string;
  impact: string;
  affectedServices: string[];
  commander: string;
  hotfixRequired?: boolean;
  rollbackRequired?: boolean;
  environment?: string;
  rootCause?: string;
  owner?: string;
}): IncidentRecord {
  const store = read();
  const now = new Date().toISOString();
  const row: IncidentRecord = {
    id: newId("inc"),
    title: input.title.trim(),
    severity: input.severity,
    status: "open",
    summary: input.summary.trim(),
    impact: input.impact.trim(),
    affectedServices: input.affectedServices,
    commander: input.commander,
    owner: input.owner || input.commander,
    environment: input.environment || process.env.TGM_LAUNCH_ENV || "controlled_beta",
    rootCause: input.rootCause,
    customerNotified: false,
    hotfixRequired: !!input.hotfixRequired,
    rollbackRequired: !!input.rollbackRequired,
    timeline: [{ at: now, by: input.commander, note: "Incident opened" }],
    createdAt: now,
    updatedAt: now,
  };
  store.incidents.unshift(row);
  write(store);
  writeAudit({
    user: input.commander,
    action: "incident_open",
    ip: "admin",
    result: "success",
    detail: `${row.id} · ${row.severity} · ${row.title}`,
  });
  return row;
}

export function updateIncident(
  id: string,
  patch: Partial<
    Pick<
      IncidentRecord,
      | "status"
      | "summary"
      | "impact"
      | "customerNotified"
      | "hotfixRequired"
      | "rollbackRequired"
      | "commander"
      | "severity"
      | "environment"
      | "rootCause"
      | "resolution"
      | "owner"
    >
  >,
  actor: string,
  note?: string
): IncidentRecord | null {
  const store = read();
  const row = store.incidents.find((i) => i.id === id);
  if (!row) return null;
  Object.assign(row, {
    ...patch,
    updatedAt: new Date().toISOString(),
  });
  if (patch.status === "resolved" || patch.status === "closed") {
    row.resolvedAt = row.resolvedAt || new Date().toISOString();
  }
  row.timeline.push({
    at: new Date().toISOString(),
    by: actor,
    note: note || `Updated · status=${row.status}`,
  });
  write(store);
  writeAudit({
    user: actor,
    action: "incident_update",
    ip: "admin",
    result: "success",
    detail: `${id} · ${row.status}`,
  });
  return row;
}

/** Flat timeline for executive incident chronology */
export function getIncidentTimeline() {
  return listIncidents().map((i) => ({
    timestamp: i.createdAt,
    updatedAt: i.updatedAt,
    id: i.id,
    title: i.title,
    environment: i.environment || "controlled_beta",
    severity: i.severity,
    affectedService: i.affectedServices.join(", "),
    impact: i.impact,
    rootCause: i.rootCause || "—",
    resolution: i.resolution || "—",
    owner: i.owner || i.commander,
    status: i.status,
    events: i.timeline,
  }));
}

export function ensureDemoIncidents(): void {
  const store = read();
  if (store.incidents.length > 0) return;
  // Intentionally empty open Criticals — seed a closed medium for process demo
  const now = new Date().toISOString();
  store.incidents.push({
    id: newId("inc"),
    title: "Staging webhook retry delay (resolved)",
    severity: "medium",
    status: "closed",
    summary: "Sandbox webhook delayed under load during Sprint 1 dry-run.",
    impact: "No production customers affected.",
    affectedServices: ["payments", "webhooks"],
    commander: "system",
    customerNotified: false,
    hotfixRequired: false,
    rollbackRequired: false,
    timeline: [
      { at: now, by: "system", note: "Opened for process seed" },
      { at: now, by: "system", note: "Closed — sandbox only" },
    ],
    createdAt: now,
    updatedAt: now,
    resolvedAt: now,
  });
  write(store);
}
