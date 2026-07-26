/**
 * Task 3 — Launch risk register.
 */
import { saveExecutiveRun } from "./store";

export type RiskSeverity = "Critical" | "High" | "Medium" | "Low";

export interface RiskItem {
  id: string;
  title: string;
  severity: RiskSeverity;
  businessImpact: string;
  technicalImpact: string;
  likelihood: "High" | "Medium" | "Low";
  mitigation: string;
  targetRelease: "Controlled Launch" | "Open Stable" | "Global Commercial" | "Post-launch";
  status: "open" | "accepted" | "mitigated";
}

export async function runLaunchRiskAssessment(): Promise<{
  risks: RiskItem[];
  criticalOpen: number;
  highOpen: number;
  launchRiskScore: number;
  at: string;
}> {
  const risks: RiskItem[] = [
    {
      id: "R-LEGAL",
      title: "Legal pack drafts not counsel-approved",
      severity: "High",
      businessImpact: "Regulatory / trust risk if open marketing before sign-off",
      technicalImpact: "None on Core; commercial pages only",
      likelihood: "High",
      mitigation: "Keep invite-only; publish counsel-approved Privacy/Terms/Refund/Risk before open Stable",
      targetRelease: "Open Stable",
      status: "open",
    },
    {
      id: "R-BRAND",
      title: "BC-BRAND Owner asset pack incomplete",
      severity: "High",
      businessImpact: "Inconsistent public brand presentation",
      technicalImpact: "None",
      likelihood: "Medium",
      mitigation: "Owner supplies Commercial/Assets per LAUNCH_ASSETS_GUIDE; Market icons already staged",
      targetRelease: "Open Stable",
      status: "open",
    },
    {
      id: "R-PSP",
      title: "Live PSP credentials not configured",
      severity: "High",
      businessImpact: "Cannot take unrestricted paid public customers via live checkout",
      technicalImpact: "Sandbox PaymentPort remains for Controlled Launch",
      likelihood: "High",
      mitigation: "Wire Paddle/PayPal live secrets or Owner written sandbox waiver for invite cohort",
      targetRelease: "Open Stable",
      status: "accepted",
    },
    {
      id: "R-AUTHENTICODE",
      title: "Authenticode Stable signing pending",
      severity: "Medium",
      businessImpact: "Windows SmartScreen warnings for some customers",
      technicalImpact: "Installer SHA-256 verification still enforced",
      likelihood: "Medium",
      mitigation: "Complete Authenticode before Global Commercial; RC checksum path OK for Controlled Launch",
      targetRelease: "Global Commercial",
      status: "open",
    },
    {
      id: "R-MQL5-SHOTS",
      title: "MQL5 live MT5 screenshots pending",
      severity: "Medium",
      businessImpact: "Market upload blocked until gallery complete",
      technicalImpact: "Website Edition unaffected",
      likelihood: "High",
      mitigation: "Capture per Assets/Market/Screenshots/CAPTURE_PLAN.md before Market Stable upload",
      targetRelease: "Global Commercial",
      status: "open",
    },
    {
      id: "R-CORE-SIGN",
      title: "Owner Core attestation signature pending",
      severity: "Medium",
      businessImpact: "Governance completeness",
      technicalImpact: "SHA-256 file certification already present and verified",
      likelihood: "Low",
      mitigation: "Owner signs RC2_CORE_CERTIFICATION statement",
      targetRelease: "Controlled Launch",
      status: "open",
    },
    {
      id: "R-EMAIL",
      title: "Transactional email provider optional in RC",
      severity: "Medium",
      businessImpact: "Missed purchase/activation emails in prod if unset",
      technicalImpact: "Outbox path exists",
      likelihood: "Medium",
      mitigation: "Configure Resend/SendGrid/SMTP before paying cohort expands",
      targetRelease: "Open Stable",
      status: "accepted",
    },
    {
      id: "R-2FA",
      title: "Admin 2FA enrollment not enforced",
      severity: "Low",
      businessImpact: "Elevated admin account risk",
      technicalImpact: "Architecture present; idle timeout active",
      likelihood: "Low",
      mitigation: "Enroll TOTP/WebAuthn for super_admin before Global Commercial",
      targetRelease: "Post-launch",
      status: "accepted",
    },
  ];

  const criticalOpen = risks.filter((r) => r.severity === "Critical" && r.status === "open").length;
  const highOpen = risks.filter((r) => r.severity === "High" && r.status === "open").length;
  // Lower risk score = more risk; invert to 0–100 readiness-style
  const launchRiskScore = Math.max(
    0,
    100 - criticalOpen * 40 - highOpen * 12 - risks.filter((r) => r.severity === "Medium" && r.status === "open").length * 4
  );

  const payload = { risks, criticalOpen, highOpen, launchRiskScore, at: new Date().toISOString() };
  saveExecutiveRun("risks", "Sprint 9 launch risk register", payload);
  return payload;
}
