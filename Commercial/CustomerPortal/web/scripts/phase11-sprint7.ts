/**
 * CLI: npm run phase11:sprint7
 */
import { runFullPhase11Sprint7Suite } from "../src/server/ai-assistant/suite";

async function main() {
  console.log("THE GOLD MIND — Phase 11 Sprint 7 Enterprise AI Assistant");
  console.log("Core Trading Engine: ISOLATED · FROZEN");
  console.log("Trading advice: PROHIBITED");
  const suite = await runFullPhase11Sprint7Suite();
  const d = suite.dashboard;
  console.log(
    JSON.stringify(
      {
        aiReadiness: d.aiReadinessScore,
        knowledgeBase: d.knowledgeBaseScore,
        supportAutomation: d.supportAutomationScore,
        security: d.securityScore,
        customerExperience: d.customerExperienceScore,
        overallPhase11Progress: d.overallPhase11Progress,
        coreMatches: d.coreMatches,
        tradingProhibited: d.tradingProhibited,
        knowledgeDocs: d.coverage.total,
        conversations: d.admin.usage.conversations,
      },
      null,
      2
    )
  );
  console.log("\nSTOP — Await Owner approval before Sprint 8.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
