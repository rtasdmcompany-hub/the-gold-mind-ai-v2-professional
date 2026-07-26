/**
 * CLI: npm run phase11:sprint3
 */
import { runFullPhase11Sprint3Suite } from "../src/server/partners/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 3 Partner Ecosystem");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  const suite = await runFullPhase11Sprint3Suite();
  console.log(
    JSON.stringify(
      {
        partnerPlatform: suite.dashboard.partnerPlatformScore,
        affiliateReadiness: suite.dashboard.affiliateReadinessScore,
        commissionEngine: suite.dashboard.commissionEngineScore,
        commercialGrowth: suite.dashboard.commercialGrowthScore,
        operationalReadiness: suite.dashboard.operationalReadinessScore,
        overallPhase11Progress: suite.dashboard.overallPhase11Progress,
        coreMatches: suite.dashboard.coreMatches,
        clicks: suite.analytics.clicks,
        sales: suite.analytics.sales,
        revenue: suite.analytics.revenue.formatted,
        referralCode: suite.portal?.referralCode,
        rules: suite.config.rules.length,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 4.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
