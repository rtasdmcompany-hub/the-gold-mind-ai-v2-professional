/**
 * Invite-only Beta roster + enrollment workflow (Phase 10 Sprint 2).
 * Commercial only — Core Trading Engine never touched.
 */
import fs from "fs";
import path from "path";
import { writeAudit } from "@/server/cloud/audit";
import { isProductionRuntime } from "@/server/security/dev-bypass";
import { decryptJson, encryptJson, launchDataDir, newId } from "./store-crypto";

export type BetaGroup =
  | "internal_team"
  | "vip_customers"
  | "professional_gold_traders"
  | "content_creators"
  | "support_team"
  | "technology_partners"
  /** @deprecated Sprint 1 aliases — migrated on read */
  | "professional_traders"
  | "selected_partners"
  | "beta_testers";

export type BetaStatus = "invited" | "accepted" | "active" | "paused" | "exited";

export type EnrollmentStep =
  | "invitation"
  | "acceptance"
  | "account_creation"
  | "license_assignment"
  | "portal_access"
  | "installer_download"
  | "installation"
  | "activation"
  | "welcome_wizard"
  | "first_successful_login"
  | "first_trading_session";

export const ENROLLMENT_STEPS: EnrollmentStep[] = [
  "invitation",
  "acceptance",
  "account_creation",
  "license_assignment",
  "portal_access",
  "installer_download",
  "installation",
  "activation",
  "welcome_wizard",
  "first_successful_login",
  "first_trading_session",
];

export const ENROLLMENT_STEP_LABELS: Record<EnrollmentStep, string> = {
  invitation: "Invitation",
  acceptance: "Acceptance",
  account_creation: "Account Creation",
  license_assignment: "License Assignment",
  portal_access: "Portal Access",
  installer_download: "Installer Download",
  installation: "Installation",
  activation: "Activation",
  welcome_wizard: "Welcome Wizard",
  first_successful_login: "First Successful Login",
  first_trading_session: "First Trading Session",
};

export type EnrollmentProgress = Partial<Record<EnrollmentStep, string>>; // ISO timestamps

export interface BetaParticipant {
  id: string;
  email: string;
  name: string;
  group: BetaGroup;
  status: BetaStatus;
  inviteCode: string;
  notes: string;
  invitedAt: string;
  acceptedAt?: string;
  lastSeenAt?: string;
  createdBy: string;
  enrollment: EnrollmentProgress;
  dailyActiveDates: string[]; // YYYY-MM-DD
}

interface BetaStore {
  version: 2;
  participants: BetaParticipant[];
  cohortCap: number;
}

const EMPTY: BetaStore = { version: 2, participants: [], cohortCap: 50 };
let cache: BetaStore | null = null;

const CANONICAL_GROUPS: BetaGroup[] = [
  "internal_team",
  "vip_customers",
  "professional_gold_traders",
  "content_creators",
  "support_team",
  "technology_partners",
];

function storePath(): string {
  return path.join(launchDataDir("beta"), "participants.enc");
}

function migrateGroup(g: string): BetaGroup {
  if (g === "professional_traders") return "professional_gold_traders";
  if (g === "selected_partners") return "technology_partners";
  if (g === "beta_testers") return "content_creators";
  if ((CANONICAL_GROUPS as string[]).includes(g)) return g as BetaGroup;
  return "content_creators";
}

function emptyEnrollment(): EnrollmentProgress {
  return {};
}

function normalizeParticipant(raw: Partial<BetaParticipant> & { email: string }): BetaParticipant {
  const enrollment = { ...(raw.enrollment || emptyEnrollment()) };
  if (!enrollment.invitation && raw.invitedAt) enrollment.invitation = raw.invitedAt;
  return {
    id: raw.id || newId("beta"),
    email: raw.email.toLowerCase(),
    name: raw.name || raw.email,
    group: migrateGroup(raw.group || "content_creators"),
    status: raw.status || "invited",
    inviteCode: raw.inviteCode || `GM-${newId("inv").slice(-8).toUpperCase()}`,
    notes: raw.notes || "",
    invitedAt: raw.invitedAt || new Date().toISOString(),
    acceptedAt: raw.acceptedAt,
    lastSeenAt: raw.lastSeenAt,
    createdBy: raw.createdBy || "system",
    enrollment,
    dailyActiveDates: Array.isArray(raw.dailyActiveDates) ? raw.dailyActiveDates : [],
  };
}

function read(): BetaStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  const raw = decryptJson<BetaStore & { version?: number }>(fs.readFileSync(p, "utf8"));
  const participants = (raw.participants || []).map((row) => normalizeParticipant(row));
  cache = {
    version: 2,
    participants,
    cohortCap: raw.cohortCap || 50,
  };
  return cache;
}

function write(data: BetaStore): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export const BETA_GROUP_LABELS: Record<string, string> = {
  internal_team: "Internal Team",
  vip_customers: "VIP Customers",
  professional_gold_traders: "Professional Gold Traders",
  content_creators: "Content Creators",
  support_team: "Support Team",
  technology_partners: "Technology Partners",
  // legacy labels for any stray rows
  professional_traders: "Professional Gold Traders",
  selected_partners: "Technology Partners",
  beta_testers: "Content Creators",
};

export function listCanonicalBetaGroups(): BetaGroup[] {
  return [...CANONICAL_GROUPS];
}

export function listBetaParticipants(filter?: { group?: BetaGroup; status?: BetaStatus; q?: string }) {
  let rows = [...read().participants];
  if (filter?.group) {
    const g = migrateGroup(filter.group);
    rows = rows.filter((p) => migrateGroup(p.group) === g);
  }
  if (filter?.status) rows = rows.filter((p) => p.status === filter.status);
  if (filter?.q) {
    const q = filter.q.toLowerCase();
    rows = rows.filter(
      (p) => p.email.includes(q) || p.name.toLowerCase().includes(q) || p.inviteCode.toLowerCase().includes(q)
    );
  }
  return rows.sort((a, b) => b.invitedAt.localeCompare(a.invitedAt));
}

export function getParticipantByEmail(email: string): BetaParticipant | null {
  const e = email.toLowerCase();
  return read().participants.find((p) => p.email === e) || null;
}

export function getParticipantById(id: string): BetaParticipant | null {
  return read().participants.find((p) => p.id === id) || null;
}

export function enrollmentCompletionPct(p: BetaParticipant): number {
  const done = ENROLLMENT_STEPS.filter((s) => !!p.enrollment[s]).length;
  return Math.round((done / ENROLLMENT_STEPS.length) * 1000) / 10;
}

export function getBetaSummary() {
  const all = read().participants;
  const byGroup = {} as Record<string, number>;
  for (const g of CANONICAL_GROUPS) byGroup[g] = 0;
  for (const p of all) {
    const g = migrateGroup(p.group);
    byGroup[g] = (byGroup[g] || 0) + 1;
  }
  const active = all.filter((p) => p.status === "active" || p.status === "accepted").length;
  const today = new Date().toISOString().slice(0, 10);
  const dau = all.filter((p) => p.dailyActiveDates.includes(today) || p.lastSeenAt?.slice(0, 10) === today).length;
  const avgEnrollment =
    all.length === 0
      ? 0
      : Math.round((all.reduce((a, p) => a + enrollmentCompletionPct(p), 0) / all.length) * 10) / 10;

  return {
    total: all.length,
    invited: all.filter((p) => p.status === "invited").length,
    active,
    dau,
    cohortCap: read().cohortCap,
    seatsRemaining: Math.max(0, read().cohortCap - all.length),
    byGroup,
    avgEnrollmentPct: avgEnrollment,
    fullyEnrolled: all.filter((p) => enrollmentCompletionPct(p) >= 100).length,
  };
}

export function addBetaParticipant(input: {
  email: string;
  name: string;
  group: BetaGroup;
  notes?: string;
  createdBy: string;
}): BetaParticipant | { error: string } {
  const store = read();
  const email = input.email.trim().toLowerCase();
  if (!email.includes("@")) return { error: "Invalid email" };
  if (store.participants.some((p) => p.email === email)) return { error: "Already enrolled" };
  if (store.participants.length >= store.cohortCap) return { error: "Cohort cap reached" };

  const now = new Date().toISOString();
  const row: BetaParticipant = {
    id: newId("beta"),
    email,
    name: input.name.trim() || email,
    group: migrateGroup(input.group),
    status: "invited",
    inviteCode: `GM-${newId("inv").slice(-8).toUpperCase()}`,
    notes: input.notes || "",
    invitedAt: now,
    createdBy: input.createdBy,
    enrollment: { invitation: now },
    dailyActiveDates: [],
  };
  store.participants.push(row);
  write(store);
  writeAudit({
    user: input.createdBy,
    action: "beta_invite",
    ip: "admin",
    result: "success",
    detail: `${email} · ${row.group}`,
  });
  return row;
}

export function updateBetaParticipant(
  id: string,
  patch: Partial<Pick<BetaParticipant, "status" | "notes" | "group" | "lastSeenAt" | "acceptedAt">>,
  actor: string
): BetaParticipant | null {
  const store = read();
  const row = store.participants.find((p) => p.id === id);
  if (!row) return null;
  if (patch.status) {
    row.status = patch.status;
    if (patch.status === "accepted" || patch.status === "active") {
      row.acceptedAt = row.acceptedAt || new Date().toISOString();
      if (!row.enrollment.acceptance) row.enrollment.acceptance = row.acceptedAt;
    }
  }
  if (patch.notes !== undefined) row.notes = patch.notes;
  if (patch.group) row.group = migrateGroup(patch.group);
  if (patch.lastSeenAt) row.lastSeenAt = patch.lastSeenAt;
  write(store);
  writeAudit({
    user: actor,
    action: "beta_update",
    ip: "admin",
    result: "success",
    detail: `${id} · ${row.status}`,
  });
  return row;
}

export function completeEnrollmentStep(
  id: string,
  step: EnrollmentStep,
  actor: string,
  at?: string
): BetaParticipant | null {
  const store = read();
  const row = store.participants.find((p) => p.id === id);
  if (!row) return null;
  const ts = at || new Date().toISOString();
  row.enrollment[step] = ts;
  row.lastSeenAt = ts;
  const day = ts.slice(0, 10);
  if (!row.dailyActiveDates.includes(day)) row.dailyActiveDates.push(day);

  if (step === "acceptance") {
    row.status = row.status === "invited" ? "accepted" : row.status;
    row.acceptedAt = row.acceptedAt || ts;
  }
  if (
    step === "first_successful_login" ||
    step === "activation" ||
    step === "first_trading_session"
  ) {
    if (row.status === "accepted" || row.status === "invited") row.status = "active";
  }

  write(store);
  writeAudit({
    user: actor,
    action: "beta_enrollment_step",
    ip: "portal",
    result: "success",
    detail: `${id} · ${step}`,
  });
  return row;
}

export function touchBetaActivity(email: string): void {
  const store = read();
  const row = store.participants.find((p) => p.email === email.toLowerCase());
  if (!row) return;
  const now = new Date().toISOString();
  row.lastSeenAt = now;
  const day = now.slice(0, 10);
  if (!row.dailyActiveDates.includes(day)) row.dailyActiveDates.push(day);
  if (!row.enrollment.portal_access) row.enrollment.portal_access = now;
  if (!row.enrollment.first_successful_login) row.enrollment.first_successful_login = now;
  if (row.status === "accepted") row.status = "active";
  write(store);
}

export function acceptInviteByCode(inviteCode: string, email: string): BetaParticipant | { error: string } {
  const store = read();
  const code = inviteCode.trim().toUpperCase();
  const row = store.participants.find((p) => p.inviteCode.toUpperCase() === code);
  if (!row) return { error: "Invalid invite code" };
  if (row.email !== email.toLowerCase()) return { error: "Invite email mismatch" };
  const now = new Date().toISOString();
  row.status = "accepted";
  row.acceptedAt = row.acceptedAt || now;
  row.enrollment.acceptance = now;
  row.enrollment.account_creation = row.enrollment.account_creation || now;
  row.enrollment.portal_access = row.enrollment.portal_access || now;
  write(store);
  writeAudit({
    user: email,
    action: "beta_accept",
    ip: "portal",
    result: "success",
    detail: row.id,
  });
  return row;
}

export function setBetaCohortCap(cap: number, actor: string): number {
  const store = read();
  store.cohortCap = Math.max(1, Math.min(500, Math.floor(cap)));
  write(store);
  writeAudit({
    user: actor,
    action: "beta_cohort_cap",
    ip: "admin",
    result: "success",
    detail: String(store.cohortCap),
  });
  return store.cohortCap;
}

export function getEnrollmentFunnel() {
  const all = read().participants;
  return ENROLLMENT_STEPS.map((step) => ({
    step,
    label: ENROLLMENT_STEP_LABELS[step],
    completed: all.filter((p) => !!p.enrollment[step]).length,
    pct: all.length === 0 ? 0 : Math.round((all.filter((p) => !!p.enrollment[step]).length / all.length) * 1000) / 10,
  }));
}

export function ensureDemoBetaParticipants(): void {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_SEED !== "true") return;
  const store = read();
  if (store.participants.length > 0) {
    // migrate groups in place
    let changed = false;
    for (const p of store.participants) {
      const g = migrateGroup(p.group);
      if (g !== p.group) {
        p.group = g;
        changed = true;
      }
      if (!p.enrollment) p.enrollment = { invitation: p.invitedAt };
      if (!p.dailyActiveDates) p.dailyActiveDates = [];
    }
    if (changed) write(store);
    return;
  }

  const now = new Date().toISOString();
  const today = now.slice(0, 10);
  const seeds: Array<{
    email: string;
    name: string;
    group: BetaGroup;
    status: BetaStatus;
    steps: EnrollmentStep[];
  }> = [
    {
      email: "qa@rtas.local",
      name: "RTAS QA",
      group: "internal_team",
      status: "active",
      steps: ENROLLMENT_STEPS,
    },
    {
      email: "support.lead@rtas.local",
      name: "Support Lead",
      group: "support_team",
      status: "active",
      steps: ENROLLMENT_STEPS.filter((s) => s !== "first_trading_session"),
    },
    {
      email: "vip.demo@goldmind.local",
      name: "VIP Demo",
      group: "vip_customers",
      status: "invited",
      steps: ["invitation"],
    },
    {
      email: "pro.trader@goldmind.local",
      name: "Gold Pro Trader",
      group: "professional_gold_traders",
      status: "active",
      steps: ENROLLMENT_STEPS,
    },
    {
      email: "creator@example.com",
      name: "Content Creator",
      group: "content_creators",
      status: "accepted",
      steps: ["invitation", "acceptance", "account_creation", "portal_access"],
    },
    {
      email: "partner@example.com",
      name: "Tech Partner",
      group: "technology_partners",
      status: "invited",
      steps: ["invitation"],
    },
  ];

  for (const s of seeds) {
    const enrollment: EnrollmentProgress = {};
    for (const step of s.steps) enrollment[step] = now;
    store.participants.push({
      id: newId("beta"),
      email: s.email,
      name: s.name,
      group: s.group,
      status: s.status,
      inviteCode: `GM-${newId("inv").slice(-8).toUpperCase()}`,
      notes: "Sprint 2 seed",
      invitedAt: now,
      acceptedAt: s.status === "active" || s.status === "accepted" ? now : undefined,
      lastSeenAt: s.status === "active" ? now : undefined,
      createdBy: "system",
      enrollment,
      dailyActiveDates: s.status === "active" ? [today] : [],
    });
  }
  write(store);
}
