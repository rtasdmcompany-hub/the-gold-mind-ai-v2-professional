/**
 * Issue resolution workflow — commercial defects only.
 * Lifecycle: Reported → Triaged → Assigned → In Progress → QA → Released → Customer Confirmation
 * Never authorizes Core Trading Engine changes.
 */
import fs from "fs";
import path from "path";
import { writeAudit } from "@/server/cloud/audit";
import { isProductionRuntime } from "@/server/security/dev-bypass";
import { decryptJson, encryptJson, launchDataDir, newId } from "./store-crypto";

export type IssuePriority = "P0" | "P1" | "P2" | "P3";
export type IssueStatus =
  | "reported"
  | "triaged"
  | "assigned"
  | "in_progress"
  | "qa_verification"
  | "released"
  | "customer_confirmation"
  | "blocked"
  | "closed"
  /** @deprecated Sprint 2 aliases */
  | "open"
  | "resolved"
  | "verified";

export type IssueKind = "bug" | "feature_request" | "ui" | "performance" | "documentation";

export interface BetaIssue {
  id: string;
  title: string;
  description: string;
  priority: IssuePriority;
  status: IssueStatus;
  kind: IssueKind;
  owner: string;
  reporter: string;
  targetFix?: string;
  releaseTarget?: string;
  verification?: string;
  resolutionDate?: string;
  customerConfirmedAt?: string;
  createdAt: string;
  updatedAt: string;
  history: Array<{ at: string; by: string; from?: string; to: string; note?: string }>;
}

interface IssueStore {
  version: 2;
  issues: BetaIssue[];
}

const EMPTY: IssueStore = { version: 2, issues: [] };
let cache: IssueStore | null = null;

export const PRIORITY_LABELS: Record<IssuePriority, string> = {
  P0: "P0 Critical",
  P1: "P1 High",
  P2: "P2 Medium",
  P3: "P3 Low",
};

export const ISSUE_LIFECYCLE: IssueStatus[] = [
  "reported",
  "triaged",
  "assigned",
  "in_progress",
  "qa_verification",
  "released",
  "customer_confirmation",
];

export const ISSUE_STATUS_LABELS: Record<string, string> = {
  reported: "Reported",
  triaged: "Triaged",
  assigned: "Assigned",
  in_progress: "In Progress",
  qa_verification: "QA Verification",
  released: "Released",
  customer_confirmation: "Customer Confirmation",
  blocked: "Blocked",
  closed: "Closed",
  open: "Reported",
  resolved: "Released",
  verified: "QA Verification",
};

function migrateStatus(s: string): IssueStatus {
  if (s === "open") return "reported";
  if (s === "resolved") return "released";
  if (s === "verified") return "qa_verification";
  return s as IssueStatus;
}

function storePath(): string {
  return path.join(launchDataDir("issues"), "issues.enc");
}

function normalize(raw: Partial<BetaIssue> & { title: string }): BetaIssue {
  return {
    id: raw.id || newId("iss"),
    title: raw.title,
    description: raw.description || "",
    priority: raw.priority || "P2",
    status: migrateStatus(raw.status || "reported"),
    kind: (raw.kind as IssueKind) || "bug",
    owner: raw.owner || "unassigned",
    reporter: raw.reporter || "system",
    targetFix: raw.targetFix,
    releaseTarget: raw.releaseTarget || raw.targetFix,
    verification: raw.verification,
    resolutionDate: raw.resolutionDate,
    customerConfirmedAt: raw.customerConfirmedAt,
    createdAt: raw.createdAt || new Date().toISOString(),
    updatedAt: raw.updatedAt || new Date().toISOString(),
    history: Array.isArray(raw.history) ? raw.history : [],
  };
}

function read(): IssueStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  const raw = decryptJson<IssueStore>(fs.readFileSync(p, "utf8"));
  cache = {
    version: 2,
    issues: (raw.issues || []).map((i) => normalize(i)),
  };
  return cache;
}

function write(data: IssueStore): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function listIssues(filter?: {
  priority?: IssuePriority;
  status?: IssueStatus;
  kind?: IssueKind;
  q?: string;
}) {
  let rows = [...read().issues];
  if (filter?.priority) rows = rows.filter((i) => i.priority === filter.priority);
  if (filter?.status) {
    const st = migrateStatus(filter.status);
    rows = rows.filter((i) => migrateStatus(i.status) === st);
  }
  if (filter?.kind) rows = rows.filter((i) => i.kind === filter.kind);
  if (filter?.q) {
    const q = filter.q.toLowerCase();
    rows = rows.filter(
      (i) => i.title.toLowerCase().includes(q) || i.id.includes(q) || i.description.toLowerCase().includes(q)
    );
  }
  return rows.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
}

export function getIssueSummary() {
  const all = read().issues;
  const done = new Set(["released", "customer_confirmation", "closed", "resolved", "verified"]);
  const openish = all.filter((i) => !done.has(migrateStatus(i.status)));
  const resolved = all.filter((i) => done.has(migrateStatus(i.status)));
  return {
    total: all.length,
    open: openish.length,
    resolved: resolved.length,
    p0Open: openish.filter((i) => i.priority === "P0").length,
    p1Open: openish.filter((i) => i.priority === "P1").length,
    bugsOpen: openish.filter((i) => i.kind === "bug").length,
    featuresOpen: openish.filter((i) => i.kind === "feature_request").length,
    byLifecycle: ISSUE_LIFECYCLE.map((s) => ({
      status: s,
      label: ISSUE_STATUS_LABELS[s],
      count: all.filter((i) => migrateStatus(i.status) === s).length,
    })),
  };
}

export function createIssue(input: {
  title: string;
  description: string;
  priority: IssuePriority;
  kind: IssueKind;
  owner: string;
  reporter: string;
  targetFix?: string;
  releaseTarget?: string;
}): BetaIssue {
  const store = read();
  const now = new Date().toISOString();
  const row: BetaIssue = {
    id: newId("iss"),
    title: input.title.trim(),
    description: input.description.trim(),
    priority: input.priority,
    status: "reported",
    kind: input.kind,
    owner: input.owner,
    reporter: input.reporter,
    targetFix: input.targetFix,
    releaseTarget: input.releaseTarget || input.targetFix,
    createdAt: now,
    updatedAt: now,
    history: [{ at: now, by: input.reporter, to: "reported", note: "Issue reported" }],
  };
  store.issues.unshift(row);
  write(store);
  writeAudit({
    user: input.reporter,
    action: "issue_create",
    ip: "admin",
    result: "success",
    detail: `${row.id} · ${row.priority} · ${row.kind}`,
  });
  return row;
}

export function updateIssue(
  id: string,
  patch: Partial<
    Pick<
      BetaIssue,
      | "status"
      | "owner"
      | "targetFix"
      | "releaseTarget"
      | "verification"
      | "priority"
      | "resolutionDate"
      | "description"
      | "customerConfirmedAt"
    >
  >,
  actor: string
): BetaIssue | null {
  const store = read();
  const row = store.issues.find((i) => i.id === id);
  if (!row) return null;
  const from = row.status;
  if (patch.status) patch.status = migrateStatus(patch.status);
  Object.assign(row, patch, { updatedAt: new Date().toISOString() });
  if (patch.status) {
    row.history.push({ at: new Date().toISOString(), by: actor, from, to: patch.status });
  }
  if (patch.status && ["released", "customer_confirmation", "closed", "qa_verification"].includes(patch.status)) {
    row.resolutionDate = row.resolutionDate || new Date().toISOString();
  }
  if (patch.status === "customer_confirmation") {
    row.customerConfirmedAt = row.customerConfirmedAt || new Date().toISOString();
  }
  if (patch.status === "assigned" && patch.owner) row.owner = patch.owner;
  write(store);
  writeAudit({
    user: actor,
    action: "issue_update",
    ip: "admin",
    result: "success",
    detail: `${id} · ${row.status}`,
  });
  return row;
}

export function ensureDemoIssues(): void {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_SEED !== "true") return;
  const store = read();
  if (store.issues.length > 0) {
    store.issues = store.issues.map((i) => normalize(i));
    write(store);
    return;
  }
  const now = new Date().toISOString();
  store.issues.push(
    normalize({
      id: newId("iss"),
      title: "Installer SmartScreen warning on unsigned RC build",
      description: "Windows shows SmartScreen for unsigned beta installer — commercial packaging only. Feedback-backed.",
      priority: "P1",
      status: "in_progress",
      kind: "bug",
      owner: "release@rtas.local",
      reporter: "qa@rtas.local",
      releaseTarget: "Sprint 4 / Authenticode",
      createdAt: now,
      updatedAt: now,
      history: [
        { at: now, by: "qa@rtas.local", to: "reported" },
        { at: now, by: "qa@rtas.local", from: "reported", to: "triaged" },
        { at: now, by: "release@rtas.local", from: "triaged", to: "in_progress" },
      ],
    }),
    normalize({
      id: newId("iss"),
      title: "Request: dark mode for portal",
      description: "Feature request — deferred; stability first. Not speculative sprint work.",
      priority: "P3",
      status: "triaged",
      kind: "feature_request",
      owner: "product@rtas.local",
      reporter: "creator@example.com",
      releaseTarget: "Post-beta",
      createdAt: now,
      updatedAt: now,
    }),
    normalize({
      id: newId("iss"),
      title: "Sandbox checkout email delay",
      description: "Validated feedback: license email delayed ~2 minutes — queue retry released.",
      priority: "P2",
      status: "customer_confirmation",
      kind: "bug",
      owner: "eng@rtas.local",
      reporter: "support.lead@rtas.local",
      releaseTarget: "Sprint 2",
      verification: "QA retest PASS",
      resolutionDate: now,
      customerConfirmedAt: now,
      createdAt: now,
      updatedAt: now,
    })
  );
  write(store);
}
