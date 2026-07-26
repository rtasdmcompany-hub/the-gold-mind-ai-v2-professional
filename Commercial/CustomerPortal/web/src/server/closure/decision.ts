/**
 * Task 9 — Final executive decision for Phase 10 closure / Phase 11 authorization.
 */
import { saveClosureRun } from "./store";

export type ClosureDecisionCode =
  | "NOT APPROVED"
  | "APPROVED WITH CONDITIONS"
  | "APPROVED FOR GLOBAL COMMERCIAL RELEASE";

export interface ClosureCondition {
  id: string;
  priority: "P0" | "P1" | "P2";
  title: string;
  owner: string;
  mitigation: string;
  targetCompletion: string;
  blocks: "Open Stable" | "Global Commercial" | "Controlled Launch governance" | "Market upload";
}

export async function runFinalClosureDecision(input: {
  criticalOpen: number;
  coreMatches: boolean;
  docsComplete: boolean;
  supportable: boolean;
  /** Owner production readiness attestation on file (2026-07-26+) */
  ownerProductionReady?: boolean;
}): Promise<{
  decision: ClosureDecisionCode;
  rationale: string[];
  conditions: ClosureCondition[];
  phase11Authorized: boolean;
  globalReleaseAuthorized: boolean;
  at: string;
}> {
  const hardStop =
    input.criticalOpen > 0 || !input.coreMatches || !input.docsComplete || !input.supportable;

  let decision: ClosureDecisionCode;
  if (hardStop) {
    decision = "NOT APPROVED";
  } else if (input.ownerProductionReady) {
    // Website Global Commercial Release authorized; Market Stable still needs C5 screenshots
    decision = "APPROVED FOR GLOBAL COMMERCIAL RELEASE";
  } else {
    // Controlled Launch program closed; Global Commercial Release still conditioned
    decision = "APPROVED WITH CONDITIONS";
  }

  const conditions: ClosureCondition[] = [
    {
      id: "C1",
      priority: "P0",
      title: "Counsel-approved Legal Pack (Privacy, Terms, Refund, Risk)",
      owner: "Owner + Legal",
      mitigation: "Counsel review of draft pages · publish signed pack · BC-LEGAL = VERIFIED",
      targetCompletion: "Before Open Stable / unrestricted public ads",
      blocks: "Open Stable",
    },
    {
      id: "C2",
      priority: "P0",
      title: "Brand assets Owner pack in Commercial/Assets",
      owner: "Owner / Brand",
      mitigation: "Deliver Owner brand pack per LAUNCH_ASSETS_GUIDE · BC-BRAND = VERIFIED",
      targetCompletion: "Before Open Stable marketing",
      blocks: "Open Stable",
    },
    {
      id: "C3",
      priority: "P0",
      title: "Live PSP credentials OR written Owner sandbox waiver",
      owner: "Engineering + Commercial + Owner",
      mitigation: "Configure live PSP or signed waiver · smoke checkout · BC-PAYLIC",
      targetCompletion: "Before first unrestricted paying public customer",
      blocks: "Open Stable",
    },
    {
      id: "C4",
      priority: "P1",
      title: "Authenticode Stable for Windows installer",
      owner: "Release Engineering",
      mitigation: "Sign Stable installer · verify Authenticode · BC-INSTALL Stable",
      targetCompletion: "Before Global Commercial Release",
      blocks: "Global Commercial",
    },
    {
      id: "C5",
      priority: "P1",
      title: "MQL5 live screenshots + rules re-read",
      owner: "Commercial + Compliance",
      mitigation: "Complete CAPTURE_PLAN · BC-MQL5 = VERIFIED",
      targetCompletion: "Before Market Stable upload",
      blocks: "Market upload",
    },
    {
      id: "C6",
      priority: "P1",
      title: "Owner signed Core attestation",
      owner: "CTO / Owner",
      mitigation: "Signed statement attached to RC2_CORE_CERTIFICATION",
      targetCompletion: "Within 14 days of Controlled Launch start",
      blocks: "Controlled Launch governance",
    },
    {
      id: "C7",
      priority: "P2",
      title: "Transactional email for cohort notifications",
      owner: "Engineering",
      mitigation: "Configure SMTP/Resend/SendGrid · send test · env verified",
      targetCompletion: "Before cohort > 50 invites",
      blocks: "Controlled Launch governance",
    },
  ];

  const rationale = hardStop
    ? ["Hard-stop triggered — Critical / Core hash / documentation / supportability."]
    : input.ownerProductionReady
      ? [
          "Owner production readiness checklist attested (legal · brand · payments · Authenticode · email · ops).",
          "Board gates BC-LEGAL through BC-SUPPORT VERIFIED (BC-MQL5 screenshots remain open for Market only).",
          "Core Trading Engine remains SHA-256 verified and frozen.",
          "Website Professional Global Commercial Release is AUTHORIZED.",
          "MQL5 Market Stable upload remains gated on C5 live screenshots.",
          "Phase 11 execution may begin when Owner explicitly starts Phase 11 work.",
        ]
      : [
          "Phase 10 Controlled Public Launch program is complete and certified.",
          "No Critical production issues remain open.",
          "Core Trading Engine remains SHA-256 verified and frozen.",
          "Platform is supportable (KB ≥20, tickets, contact, ops runbooks).",
          "Project documentation pack for Phase 10 closure is complete.",
          "Global Commercial Release is NOT authorized until P0 conditions C1–C3 clear (and C4–C5 for Global/Market).",
          "Phase 11 = Global Commercial Release planning — authorized; execution awaits Owner approval.",
        ];

  // When Owner-cleared, only Market screenshot condition remains open for Stable Market upload
  const activeConditions = input.ownerProductionReady
    ? conditions.filter((c) => c.id === "C5")
    : conditions;

  const payload = {
    decision,
    rationale,
    conditions: activeConditions,
    phase11Authorized:
      decision === "APPROVED WITH CONDITIONS" ||
      decision === "APPROVED FOR GLOBAL COMMERCIAL RELEASE",
    globalReleaseAuthorized: decision === "APPROVED FOR GLOBAL COMMERCIAL RELEASE",
    at: new Date().toISOString(),
  };
  saveClosureRun("decision", "Sprint 10 final executive decision", payload);
  return payload;
}
