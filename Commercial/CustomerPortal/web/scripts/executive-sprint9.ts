/**
 * CLI: npm run executive:sprint9
 */
import { runFullExecutiveSuite } from "../src/server/executive/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 10 Sprint 9 Executive Go / No-Go");
  console.log("Core Trading Engine: ISOLATED");
  const suite = await runFullExecutiveSuite();
  console.log(
    JSON.stringify(
      {
        decision: suite.decision.decision,
        executiveReadiness: suite.dashboard.executiveReadinessScore,
        productionReadiness: suite.dashboard.productionReadinessScore,
        commercialReadiness: suite.dashboard.commercialReadinessScore,
        operationalReadiness: suite.dashboard.operationalReadinessScore,
        launchRisk: suite.dashboard.launchRiskScore,
        overallProject: suite.dashboard.overallProjectScore,
        phase10Progress: suite.dashboard.phase10Progress,
        criticalOpen: suite.risks.criticalOpen,
        highOpen: suite.risks.highOpen,
        conditions: suite.decision.conditions.map((c) => ({
          id: c.id,
          priority: c.priority,
          title: c.title,
        })),
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
