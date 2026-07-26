/**
 * CLI: npm run phase11:sprint6
 */
import { runFullPhase11Sprint6Suite } from "../src/server/mobile/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 6 Mobile Companion");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  console.log("Trading on mobile: PROHIBITED");
  const suite = await runFullPhase11Sprint6Suite();
  const d = suite.dashboardFull;
  console.log(
    JSON.stringify(
      {
        mobilePlatform: d.mobilePlatformScore,
        security: d.securityScore,
        customerExperience: d.customerExperienceScore,
        apiIntegration: d.apiIntegrationScore,
        enterpriseMobility: d.enterpriseMobilityScore,
        overallPhase11Progress: d.overallPhase11Progress,
        coreMatches: d.coreMatches,
        tradingProhibited: d.tradingProhibited,
        devices: d.devices.length,
        pushDelivered: d.pushDelivered,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 7.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
