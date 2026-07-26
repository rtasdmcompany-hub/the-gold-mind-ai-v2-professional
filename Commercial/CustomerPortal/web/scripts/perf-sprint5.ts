/**
 * CLI: npm run perf:sprint5
 * Commercial performance suite — never touches Core Trading Engine.
 */
import { runFullPerformanceSuite } from "../src/server/performance/dashboard";

async function main() {
  console.log("THE GOLD MIND — Phase 10 Sprint 5 performance suite");
  console.log("Core Trading Engine: ISOLATED (not imported)");
  const suite = await runFullPerformanceSuite();
  console.log(
    JSON.stringify(
      {
        performance: suite.benchmark.score,
        scalability: suite.scalability.score,
        load: suite.load.score,
        database: suite.database.score,
        cloud: suite.cloud.score,
        resilience: suite.resilience.score,
        avgMs: suite.dashboard.averageResponseTime,
        p95: suite.dashboard.p95ResponseTime,
        p99: suite.dashboard.p99ResponseTime,
        apiSuccessRate: suite.dashboard.apiSuccessRate,
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
