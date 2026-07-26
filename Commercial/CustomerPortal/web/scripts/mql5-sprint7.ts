/**
 * CLI: npm run mql5:sprint7
 * Market packaging suite — never touches Core Trading Engine.
 */
import { runFullMarketSuite } from "../src/server/market/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 10 Sprint 7 MQL5 Market suite");
  console.log("Core Trading Engine: READ-ONLY SHA verification (not modified)");
  const suite = await runFullMarketSuite();
  console.log(
    JSON.stringify(
      {
        mql5Readiness: suite.dashboard.mql5ReadinessScore,
        commercialPackaging: suite.dashboard.commercialPackagingScore,
        documentation: suite.dashboard.documentationScore,
        compliance: suite.dashboard.complianceScore,
        releaseReadiness: suite.dashboard.releaseReadinessScore,
        customerReadiness: suite.dashboard.customerReadinessScore,
        storeSubmissionReadiness: suite.dashboard.storeSubmissionReadiness,
        coreMatchesCert: suite.dashboard.coreMatchesCert,
        remainingBlockers: suite.dashboard.remainingBlockers,
      },
      null,
      2
    )
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
