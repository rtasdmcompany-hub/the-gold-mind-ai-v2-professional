/**
 * CLI: npm run phase11:sprint8
 */
import { runFullPhase11Sprint8Suite } from "../src/server/api-platform/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 8 Enterprise API Platform");
  console.log("Core Trading Engine: ISOLATED · FROZEN · NOT API-ACCESSIBLE");
  const suite = await runFullPhase11Sprint8Suite();
  const d = suite.dashboard;
  console.log(
    JSON.stringify(
      {
        apiPlatform: d.apiPlatformScore,
        developerExperience: d.developerExperienceScore,
        security: d.securityScore,
        integrationReadiness: d.integrationReadinessScore,
        scalability: d.scalabilityScore,
        overallPhase11Progress: d.overallPhase11Progress,
        coreMatches: d.coreMatches,
        tradingExposed: d.tradingExposed,
        endpoints: d.endpointCount,
        deliveries: d.deliveries,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 9.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
