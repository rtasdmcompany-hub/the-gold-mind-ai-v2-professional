/**
 * CLI: npm run phase11:sprint5
 */
import { runFullPhase11Sprint5Suite } from "../src/server/i18n/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 5 Localization");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  const suite = await runFullPhase11Sprint5Suite();
  console.log(
    JSON.stringify(
      {
        localization: suite.dashboard.localizationScore,
        internationalReadiness: suite.dashboard.internationalReadinessScore,
        translationQuality: suite.dashboard.translationQualityScore,
        regionalExpansion: suite.dashboard.regionalExpansionScore,
        compliance: suite.dashboard.complianceScore,
        overallPhase11Progress: suite.dashboard.overallPhase11Progress,
        coreMatches: suite.dashboard.coreMatches,
        locales: suite.dashboard.locales.length,
        masterKeys: suite.dashboard.masterKeyCount,
        avgCompleteness: suite.qa.averageCompleteness,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 6.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
