/**
 * Executive Market dashboard — Phase 10 Sprint 7.
 */
import { runEditionVerification } from "./edition";
import { runMql5ComplianceReview } from "./compliance";
import { runStoreAssetInventory } from "./assets";
import { runDocumentationInventory } from "./documentation";
import { runStoreMetadata } from "./metadata";
import { runCommercialValidation } from "./validation";
import { runSubmissionChecklist } from "./submission";
import { latestMarketRun, listMarketRuns } from "./store";

export async function ensureSprint7Evidence(force = false) {
  if (!force && latestMarketRun("edition") && latestMarketRun("compliance") && latestMarketRun("submission")) {
    return;
  }
  await runFullMarketSuite();
}

export async function runFullMarketSuite() {
  const edition = await runEditionVerification();
  const compliance = await runMql5ComplianceReview();
  const assets = await runStoreAssetInventory();
  const documentation = await runDocumentationInventory();
  const metadata = await runStoreMetadata();
  const validation = await runCommercialValidation();
  const submission = await runSubmissionChecklist();
  const dashboard = await getExecutiveMarketDashboard();
  return { edition, compliance, assets, documentation, metadata, validation, submission, dashboard };
}

export async function getExecutiveMarketDashboard(options?: { refresh?: boolean }) {
  await ensureSprint7Evidence(!!options?.refresh);

  const edition = latestMarketRun("edition")?.payload as { score?: number; coreMatchesCert?: boolean } | undefined;
  const compliance = latestMarketRun("compliance")?.payload as { score?: number } | undefined;
  const assets = latestMarketRun("assets")?.payload as { score?: number } | undefined;
  const documentation = latestMarketRun("documentation")?.payload as { score?: number } | undefined;
  const metadata = latestMarketRun("metadata")?.payload as { score?: number } | undefined;
  const validation = latestMarketRun("validation")?.payload as { score?: number } | undefined;
  const submission = latestMarketRun("submission")?.payload as {
    score?: number;
    storeSubmissionReadiness?: string;
    remainingBlockers?: string[];
  } | undefined;

  const marketComplianceScore = compliance?.score ?? 0;
  const documentationScore = documentation?.score ?? 0;
  const commercialPackagingScore = Math.round(
    ((edition?.score ?? 0) + (assets?.score ?? 0) + (metadata?.score ?? 0)) / 3
  );
  const customerReadinessScore = Math.round(((validation?.score ?? 0) + documentationScore) / 2);
  const mql5ReadinessScore = Math.round(
    (marketComplianceScore + commercialPackagingScore + documentationScore + (submission?.score ?? 0)) / 4
  );
  const complianceScore = marketComplianceScore;
  const releaseReadinessScore = Math.round(
    ((submission?.score ?? 0) + (validation?.score ?? 0) + (edition?.coreMatchesCert ? 100 : 0)) / 3
  );

  return {
    mql5ReadinessScore,
    commercialPackagingScore,
    documentationScore,
    complianceScore,
    marketComplianceScore,
    customerReadinessScore,
    releaseReadinessScore,
    storeSubmissionReadiness: submission?.storeSubmissionReadiness ?? "UNKNOWN",
    remainingBlockers: submission?.remainingBlockers ?? [],
    coreMatchesCert: !!edition?.coreMatchesCert,
    coreIsolation: "Market suite never modifies Core Trading Engine — SHA verification only",
    runs: listMarketRuns()
      .slice(0, 14)
      .map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}
