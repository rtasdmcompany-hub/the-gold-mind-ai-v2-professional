/**
 * CLI: npm run phase11:sprint4
 */
import { runFullPhase11Sprint4Suite } from "../src/server/enterprise/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 4 Enterprise CRM");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  const suite = await runFullPhase11Sprint4Suite();
  console.log(
    JSON.stringify(
      {
        crm: suite.dashboard.crmScore,
        enterpriseManagement: suite.dashboard.enterpriseManagementScore,
        teamLicensing: suite.dashboard.teamLicensingScore,
        rbac: suite.dashboard.rbacScore,
        enterpriseReadiness: suite.dashboard.enterpriseReadinessScore,
        overallPhase11Progress: suite.dashboard.overallPhase11Progress,
        coreMatches: suite.dashboard.coreMatches,
        orgId: suite.org.id,
        orgs: suite.crm.totalOrgs,
        health: suite.success.organizationHealth.score,
        seatsAssigned: suite.success.activeSeats,
        roles: suite.roles.length,
        auditEntries: suite.audit.totals.auditEntries,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 5.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
