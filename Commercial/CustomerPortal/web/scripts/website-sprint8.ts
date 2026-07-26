/**
 * CLI: npm run website:sprint8
 * Website Professional launch suite — never touches Core Trading Engine.
 */
import { runFullWebsiteLaunchSuite } from "../src/server/website-launch/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 10 Sprint 8 Website launch suite");
  console.log("Core Trading Engine: ISOLATED (SHA verify only)");
  const suite = await runFullWebsiteLaunchSuite();
  console.log(
    JSON.stringify(
      {
        websiteProduction: suite.dashboard.websiteProductionScore,
        deployment: suite.dashboard.deploymentScore,
        customerJourney: suite.dashboard.customerJourneyScore,
        commercialOperations: suite.dashboard.commercialOperationsScore,
        launchReadiness: suite.dashboard.launchReadinessScore,
        websiteReadiness: suite.dashboard.websiteReadinessScore,
        commercialReadiness: suite.dashboard.commercialReadinessScore,
        operationalReadiness: suite.dashboard.operationalReadinessScore,
        customerExperience: suite.dashboard.customerExperienceScore,
        launchStatus: suite.dashboard.launchStatus,
        coreMatches: suite.dashboard.coreMatches,
        remainingRisks: suite.dashboard.remainingRisks,
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
