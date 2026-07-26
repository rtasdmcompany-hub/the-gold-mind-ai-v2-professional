/**
 * CLI: npm run phase11:sprint2
 */
import { runFullPhase11Sprint2Suite } from "../src/server/phase11/bi/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 2 Business Intelligence");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  const suite = await runFullPhase11Sprint2Suite();
  console.log(
    JSON.stringify(
      {
        businessIntelligence: suite.dashboard.businessIntelligenceScore,
        revenueReadiness: suite.dashboard.revenueReadinessScore,
        commercialIntelligence: suite.dashboard.commercialIntelligenceScore,
        executiveReporting: suite.dashboard.executiveReportingScore,
        growthReadiness: suite.dashboard.growthReadinessScore,
        revenueAnalytics: suite.dashboard.revenueAnalyticsScore,
        forecastAccuracyReadiness: suite.dashboard.forecastAccuracyReadiness,
        customerAnalytics: suite.dashboard.customerAnalyticsScore,
        operationalAnalytics: suite.dashboard.operationalAnalyticsScore,
        overallPhase11Progress: suite.dashboard.overallPhase11Progress,
        coreMatches: suite.dashboard.coreMatches,
        mrr: suite.executive.mrr.formatted,
        countryKind: suite.revenue.revenueByCountry.kind,
        forecastDisclaimer: suite.forecast.disclaimer.slice(0, 80),
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 3.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
