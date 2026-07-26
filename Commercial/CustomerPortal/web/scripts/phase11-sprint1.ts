/**
 * CLI: npm run phase11:sprint1
 */
import { runFullPhase11Sprint1Suite } from "../src/server/phase11/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 1 Global Commercial Operations");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  const suite = await runFullPhase11Sprint1Suite();
  console.log(
    JSON.stringify(
      {
        businessOperations: suite.dashboard.businessOperationsScore,
        commercialOperations: suite.dashboard.commercialOperationsScore,
        customerSuccess: suite.dashboard.customerSuccessScore,
        operationalHealth: suite.dashboard.operationalHealthScore,
        executiveReadiness: suite.dashboard.executiveReadinessScore,
        overallPhase11Progress: suite.dashboard.overallPhase11Progress,
        coreMatches: suite.dashboard.coreMatches,
        workflows: suite.commercial.workflows.map((w) => ({
          id: w.id,
          status: w.status,
        })),
        reports: suite.reports.reports.map((r) => r.kind),
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 2.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
