/**
 * CLI: npm run closure:sprint10
 */
import { runFullClosureSuite } from "../src/server/closure/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 10 Sprint 10 Project Closure");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  const suite = await runFullClosureSuite();
  console.log(
    JSON.stringify(
      {
        decision: suite.decision.decision,
        phase11Authorized: suite.decision.phase11Authorized,
        globalReleaseAuthorized: suite.decision.globalReleaseAuthorized,
        overallProduct: suite.dashboard.overallProductScore,
        engineering: suite.dashboard.engineeringScore,
        commercial: suite.dashboard.commercialScore,
        operational: suite.dashboard.operationalScore,
        security: suite.dashboard.securityScore,
        customerExperience: suite.dashboard.customerExperienceScore,
        productionReadiness: suite.dashboard.productionReadinessScore,
        finalExecutiveRating: suite.dashboard.finalExecutiveRating,
        phase10Progress: suite.dashboard.phase10Progress,
        coreMatches: suite.architecture.coreMatches,
        conditions: suite.decision.conditions.map((c) => ({
          id: c.id,
          priority: c.priority,
          title: c.title,
          owner: c.owner,
          target: c.targetCompletion,
        })),
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before beginning Phase 11.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
