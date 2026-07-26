/**
 * CLI: npm run phase11:sprint9
 */
import { runFullPhase11Sprint9Suite } from "../src/server/infrastructure/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 9 Global Infrastructure");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  const suite = await runFullPhase11Sprint9Suite();
  const d = suite.dashboard;
  console.log(
    JSON.stringify(
      {
        infrastructure: d.infrastructureScore,
        scalability: d.scalabilityScore,
        availability: d.availabilityScore,
        operationalExcellence: d.operationalExcellenceScore,
        businessContinuity: d.businessContinuityScore,
        overallPhase11Progress: d.overallPhase11Progress,
        coreMatches: d.coreMatches,
        globalHealth: d.ops.globalHealth.status,
        monthlySpendUsd: d.ops.cloudSpend.monthlyUsd,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 10.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
