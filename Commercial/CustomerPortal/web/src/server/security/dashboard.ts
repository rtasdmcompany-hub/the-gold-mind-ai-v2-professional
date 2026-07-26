/**
 * Executive Security Dashboard — Phase 10 Sprint 6.
 */
import { runSecurityAssessment } from "./assessment";
import { runPenetrationTests } from "./penetration";
import { runOwaspReview } from "./owasp";
import { runSecretManagementReview } from "./secrets-review";
import { runDataProtectionReview } from "./data-protection";
import { runDisasterRecoveryValidation } from "./disaster-recovery";
import { runComplianceReview } from "./compliance";
import { latestSecurityRun, listSecurityRuns, type SecurityFinding } from "./store";

export async function ensureSprint6Evidence(force = false) {
  if (
    !force &&
    latestSecurityRun("assessment") &&
    latestSecurityRun("pentest") &&
    latestSecurityRun("owasp")
  ) {
    return;
  }
  await runFullSecuritySuite();
}

export async function runFullSecuritySuite() {
  const assessment = await runSecurityAssessment();
  const pentest = await runPenetrationTests();
  const owasp = await runOwaspReview();
  const secrets = await runSecretManagementReview();
  const dataProtection = await runDataProtectionReview();
  const disasterRecovery = await runDisasterRecoveryValidation();
  const compliance = await runComplianceReview();
  const dashboard = await getExecutiveSecurityDashboard();
  return {
    assessment,
    pentest,
    owasp,
    secrets,
    dataProtection,
    disasterRecovery,
    compliance,
    dashboard,
  };
}

function collectFindings(): SecurityFinding[] {
  const kinds = [
    "assessment",
    "pentest",
    "owasp",
    "secrets",
    "data_protection",
    "disaster_recovery",
    "compliance",
  ] as const;
  const out: SecurityFinding[] = [];
  for (const k of kinds) {
    const p = latestSecurityRun(k)?.payload as { findings?: SecurityFinding[] } | undefined;
    if (p?.findings) out.push(...p.findings);
  }
  return out;
}

export async function getExecutiveSecurityDashboard(options?: { refresh?: boolean }) {
  await ensureSprint6Evidence(!!options?.refresh);

  const assessment = latestSecurityRun("assessment")?.payload as { score?: number } | undefined;
  const pentest = latestSecurityRun("pentest")?.payload as {
    score?: number;
    criticalOpen?: number;
    highOpen?: number;
  } | undefined;
  const owasp = latestSecurityRun("owasp")?.payload as { score?: number } | undefined;
  const secrets = latestSecurityRun("secrets")?.payload as { score?: number } | undefined;
  const dataProtection = latestSecurityRun("data_protection")?.payload as { score?: number } | undefined;
  const disasterRecovery = latestSecurityRun("disaster_recovery")?.payload as { score?: number } | undefined;
  const compliance = latestSecurityRun("compliance")?.payload as { score?: number } | undefined;

  const findings = collectFindings();
  const openCrit = findings.filter((f) => f.status === "open" && f.severity === "Critical").length;
  const openHigh = findings.filter((f) => f.status === "open" && f.severity === "High").length;
  const openMed = findings.filter((f) => f.status === "open" && f.severity === "Medium").length;

  const securityScore = assessment?.score ?? 0;
  const pentestScore = pentest?.score ?? 0;
  const complianceScore = compliance?.score ?? 0;
  const disasterRecoveryScore = disasterRecovery?.score ?? 0;
  const owaspScore = owasp?.score ?? 0;
  const secretsScore = secrets?.score ?? 0;
  const dataScore = dataProtection?.score ?? 0;

  const operationalSecurityScore = Math.round(
    (pentestScore + disasterRecoveryScore + secretsScore + dataScore) / 4
  );
  const commercialSecurityScore = Math.round((securityScore + owaspScore + complianceScore) / 3);
  const overallSecurityScore = Math.round(
    (securityScore + pentestScore + owaspScore + secretsScore + dataScore + disasterRecoveryScore) / 6
  );
  const complianceReadinessScore = complianceScore;

  const productionSecurityReadiness =
    openCrit === 0 && openHigh === 0
      ? "READY_WITH_CONDITIONS"
      : openCrit > 0
        ? "BLOCKED_CRITICAL"
        : "BLOCKED_HIGH";

  const remainingRisks = findings
    .filter((f) => f.status === "open" || f.status === "accepted")
    .filter((f) => f.severity === "Critical" || f.severity === "High" || f.severity === "Medium")
    .slice(0, 12)
    .map((f) => ({
      severity: f.severity,
      title: f.title,
      status: f.status,
      area: f.area,
    }));

  return {
    overallSecurityScore,
    securityScore,
    penetrationTestingScore: pentestScore,
    complianceScore,
    complianceReadinessScore,
    disasterRecoveryScore,
    operationalSecurityScore,
    commercialSecurityScore,
    owaspScore,
    secretsScore,
    dataProtectionScore: dataScore,
    productionSecurityReadiness,
    openCritical: openCrit,
    openHigh: openHigh,
    openMedium: openMed,
    remainingRisks,
    coreIsolation: "Security suite never imports or modifies Core Trading Engine",
    runs: listSecurityRuns()
      .slice(0, 14)
      .map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}
