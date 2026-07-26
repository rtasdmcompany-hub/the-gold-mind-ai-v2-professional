/**
 * Controlled launch environments — commercial deployment only.
 * Never controls or modifies the Core Trading Engine.
 */

export type LaunchEnvironmentId =
  | "development"
  | "internal_qa"
  | "staging"
  | "production"
  | "controlled_beta"
  | "public_stable";

export interface LaunchEnvironment {
  id: LaunchEnvironmentId;
  name: string;
  purpose: string;
  customerAccess: "none" | "internal" | "invite_only" | "public";
  paymentMode: "sandbox" | "live" | "disabled";
  releaseChannel: "dev" | "rc" | "stable";
  monitoringRequired: boolean;
  incidentSla: "best_effort" | "business_hours" | "24x7";
  corePolicy: "FROZEN";
  deployRules: string[];
}

export const LAUNCH_ENVIRONMENTS: LaunchEnvironment[] = [
  {
    id: "development",
    name: "Development",
    purpose: "Feature work for commercial portal, licensing, billing, installer UX.",
    customerAccess: "none",
    paymentMode: "sandbox",
    releaseChannel: "dev",
    monitoringRequired: false,
    incidentSla: "best_effort",
    corePolicy: "FROZEN",
    deployRules: [
      "Local or ephemeral cloud only",
      "No real customer PII beyond fixtures",
      "Sandbox payment providers only",
      "Core EA binary never rebuilt from this environment",
    ],
  },
  {
    id: "internal_qa",
    name: "Internal QA",
    purpose: "Regression of commercial flows before staging promotion.",
    customerAccess: "internal",
    paymentMode: "sandbox",
    releaseChannel: "rc",
    monitoringRequired: true,
    incidentSla: "business_hours",
    corePolicy: "FROZEN",
    deployRules: [
      "Promote only from tagged commercial builds",
      "RC-2 harness + tsc must PASS",
      "Core SHA-256 must match certified hash",
      "No live payment credentials",
    ],
  },
  {
    id: "staging",
    name: "Staging",
    purpose: "Production-like dress rehearsal for portal, webhooks, updates.",
    customerAccess: "internal",
    paymentMode: "sandbox",
    releaseChannel: "rc",
    monitoringRequired: true,
    incidentSla: "business_hours",
    corePolicy: "FROZEN",
    deployRules: [
      "Mirror production config shape with sandbox secrets",
      "Webhook HMAC + idempotency smoke required",
      "Installer/update checksum verification required",
      "Rollback package retained before each promote",
    ],
  },
  {
    id: "production",
    name: "Production",
    purpose: "Live commercial infrastructure hosting portal and APIs.",
    customerAccess: "invite_only",
    paymentMode: "live",
    releaseChannel: "stable",
    monitoringRequired: true,
    incidentSla: "24x7",
    corePolicy: "FROZEN",
    deployRules: [
      "Owner + Release Engineering dual approval",
      "Phase 10 conditions C1–C5 satisfied or Owner-waived in writing",
      "Health endpoint green before traffic",
      "Secrets via env/vault — never committed",
      "Hotfix only for Critical commercial bugs outside Core",
    ],
  },
  {
    id: "controlled_beta",
    name: "Controlled Beta",
    purpose: "Invite-only real-world validation with tracked cohorts.",
    customerAccess: "invite_only",
    paymentMode: "live",
    releaseChannel: "rc",
    monitoringRequired: true,
    incidentSla: "24x7",
    corePolicy: "FROZEN",
    deployRules: [
      "Participants must exist in beta roster",
      "Cohort caps enforced before invite expansion",
      "Satisfaction and stability gates before next cohort",
      "No open marketing / unrestricted signup",
    ],
  },
  {
    id: "public_stable",
    name: "Future Public Stable",
    purpose: "Global release — NOT authorized in Sprint 1.",
    customerAccess: "public",
    paymentMode: "live",
    releaseChannel: "stable",
    monitoringRequired: true,
    incidentSla: "24x7",
    corePolicy: "FROZEN",
    deployRules: [
      "Blocked until Controlled Beta targets met",
      "All board gates VERIFIED",
      "Authenticode Stable preferred",
      "Owner written GO for open public",
    ],
  },
];

export function getLaunchEnvironment(id: LaunchEnvironmentId): LaunchEnvironment | undefined {
  return LAUNCH_ENVIRONMENTS.find((e) => e.id === id);
}

export function getActiveLaunchMode(): LaunchEnvironmentId {
  const raw = (process.env.TGM_LAUNCH_ENV || "controlled_beta").toLowerCase();
  if (LAUNCH_ENVIRONMENTS.some((e) => e.id === raw)) return raw as LaunchEnvironmentId;
  return "controlled_beta";
}

export function assertNotPublicStableUnlessAuthorized(): { ok: boolean; reason: string } {
  const mode = getActiveLaunchMode();
  if (mode === "public_stable" && process.env.TGM_PUBLIC_STABLE_AUTHORIZED !== "1") {
    return { ok: false, reason: "Public Stable blocked — set TGM_PUBLIC_STABLE_AUTHORIZED=1 only after Owner GO" };
  }
  return { ok: true, reason: `Active mode: ${mode}` };
}
