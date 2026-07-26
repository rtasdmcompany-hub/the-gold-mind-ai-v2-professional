/**
 * CLI: npm run security:sprint6
 * Commercial security suite — never touches Core Trading Engine.
 */
import { runFullSecuritySuite } from "../src/server/security/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 10 Sprint 6 security suite");
  console.log("Core Trading Engine: ISOLATED (not imported)");
  const suite = await runFullSecuritySuite();
  console.log(
    JSON.stringify(
      {
        overallSecurity: suite.dashboard.overallSecurityScore,
        security: suite.dashboard.securityScore,
        pentest: suite.dashboard.penetrationTestingScore,
        compliance: suite.dashboard.complianceScore,
        complianceReadiness: suite.dashboard.complianceReadinessScore,
        disasterRecovery: suite.dashboard.disasterRecoveryScore,
        operationalSecurity: suite.dashboard.operationalSecurityScore,
        commercialSecurity: suite.dashboard.commercialSecurityScore,
        productionReadiness: suite.dashboard.productionSecurityReadiness,
        openCritical: suite.dashboard.openCritical,
        openHigh: suite.dashboard.openHigh,
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
