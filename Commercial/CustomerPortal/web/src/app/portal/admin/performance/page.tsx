import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getExecutivePerformanceDashboard } from "@/server/performance/dashboard";
import { actionRunFullPerfSuite } from "@/server/performance/actions";

export default async function PerformanceDashboardPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (
    !hasPermission(role, "admin.observability.read")
  ) {
    redirect("/portal/admin");
  }

  const dash = await getExecutivePerformanceDashboard();
  const canWrite = hasPermission(role, "admin.observability.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Performance Dashboard</h1>
        <p className="page-sub">
          Commercial platform only · Core {dash.coreIsolation.includes("never") ? "ISOLATED" : "CHECK"} · health{" "}
          <StatusBadge status={dash.platformHealth} />
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation}
      </div>

      {canWrite && (
        <form action={actionRunFullPerfSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Run full Sprint 5 performance suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Average Response Time</h3>
          <div className="value">{dash.averageResponseTime} ms</div>
        </div>
        <div className="card">
          <h3>P95 Response Time</h3>
          <div className="value">{dash.p95ResponseTime} ms</div>
        </div>
        <div className="card">
          <h3>P99 Response Time</h3>
          <div className="value">{dash.p99ResponseTime} ms</div>
        </div>
        <div className="card">
          <h3>Peak Concurrent Users</h3>
          <div className="value">{dash.peakConcurrentUsers}</div>
        </div>
        <div className="card">
          <h3>System Uptime</h3>
          <div className="value">{dash.systemUptimeSec}s</div>
        </div>
        <div className="card">
          <h3>CPU Utilization</h3>
          <div className="value">{dash.cpuUtilization}%</div>
        </div>
        <div className="card">
          <h3>Memory Utilization</h3>
          <div className="value">{dash.memoryUtilization} MB</div>
        </div>
        <div className="card">
          <h3>Database Load</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.databaseMs ? `${dash.databaseMs} ms @100` : dash.databaseLoad}
          </div>
        </div>
        <div className="card">
          <h3>API Success Rate</h3>
          <div className="value">{dash.apiSuccessRate}%</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Suite scores</h2>
      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        {Object.entries(dash.scores).map(([k, v]) => (
          <div className="card" key={k}>
            <h3>{k}</h3>
            <div className="value">{v}</div>
          </div>
        ))}
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        <Link className="btn" href="/portal/admin/benchmarks">
          Benchmarks
        </Link>
        <Link className="btn" href="/portal/admin/scalability">
          Scalability
        </Link>
        <Link className="btn" href="/portal/admin/load-tests">
          Load Tests
        </Link>
        <Link className="btn" href="/portal/admin/database-optimization">
          Database
        </Link>
        <Link className="btn" href="/portal/admin/cloud-performance">
          Cloud
        </Link>
        <Link className="btn" href="/portal/admin/resilience">
          Resilience
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
