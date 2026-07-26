/**
 * CLI: npm run phase11:sprint10
 */
import { runFullPhase11Sprint10Suite } from "../src/server/phase11-closure/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 10 Global Enterprise Certification");
  console.log("Core Trading Engine: ISOLATED · FROZEN · SHA VERIFICATION MANDATORY");
  const suite = await runFullPhase11Sprint10Suite();
  const d = suite.dashboard;
  console.log(
    JSON.stringify(
      {
        decision: d.decision,
        phase12Authorized: d.phase12Authorized,
        engineering: d.engineeringScore,
        commercial: d.commercialScore,
        operations: d.operationsScore,
        security: d.securityScore,
        infrastructure: d.infrastructureScore,
        enterprise: d.enterpriseScore,
        customerSuccess: d.customerSuccessScore,
        globalReadiness: d.globalReadinessScore,
        overallProduct: d.overallProductScore,
        phase11Progress: d.phase11Progress,
        coreMatches: d.coreMatches,
        conditions: d.conditions.map((c) => `${c.id}:${c.severity}`),
        stats: {
          modules: d.stats.architectureModules,
          docs: d.stats.documentationFiles,
          apis: d.stats.apis,
          dashboards: d.stats.dashboards,
          completion: d.stats.overallProjectCompletionPct,
        },
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before beginning Phase 12.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
