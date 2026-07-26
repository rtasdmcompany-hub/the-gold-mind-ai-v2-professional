/**
 * CLI: npm run phase12:sprint1
 */
import { runFullPhase12LtsSuite } from "../src/server/phase12/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 12 Sprint 1 LTS Activation");
  console.log("Core Trading Engine: PERMANENTLY FROZEN · SHA VERIFICATION MANDATORY");
  console.log("Scope: Operational excellence — NOT feature development");
  const suite = await runFullPhase12LtsSuite();
  const d = suite.dashboard;
  console.log(
    JSON.stringify(
      {
        portalVersion: d.portalVersion,
        customerSuccessScore: d.scores.customerSuccessScore,
        supportScore: d.scores.supportScore,
        businessGrowthScore: d.scores.businessGrowthScore,
        operationalExcellenceScore: d.scores.operationalExcellenceScore,
        infrastructureHealth: d.scores.infrastructureHealth,
        overallPlatformHealth: d.scores.overallPlatformHealth,
        phase12Progress: d.scores.phase12Progress,
        coreMatches: d.coreMatches,
        v2EngineeringAuthorized: d.v2EngineeringAuthorized,
        conditions: d.conditions.map((c: { id: string; severity: string }) => `${c.id}:${c.severity}`),
        monthlyReports: suite.reportFiles.length,
        v2Backlog: suite.v2.backlogCount,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Version 2.x Engineering Program.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
