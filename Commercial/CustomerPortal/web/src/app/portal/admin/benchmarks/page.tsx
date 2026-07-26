import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureSprint5Evidence } from "@/server/performance/dashboard";
import { latestPerfRun } from "@/server/performance/store";
import { actionRunBenchmarks } from "@/server/performance/actions";
import type { BenchmarkResult } from "@/server/performance/benchmarks";

export default async function BenchmarksPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.observability.read") && actor !== "admin@goldmind.local") {
    redirect("/portal/admin");
  }
  await ensureSprint5Evidence();
  const run = latestPerfRun("benchmark");
  const payload = run?.payload as { results: BenchmarkResult[]; score: number; at: string } | undefined;
  const canWrite = hasPermission(role, "admin.observability.write") || actor === "admin@goldmind.local";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Performance Benchmarking</h1>
        <p className="page-sub">Score {payload?.score ?? "—"} · commercial probes only</p>
      </header>
      {canWrite && (
        <form action={actionRunBenchmarks} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run benchmarks
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Metric</th>
              <th>Avg</th>
              <th>P95</th>
              <th>Target</th>
              <th>Pass</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.results || []).map((r) => (
              <tr key={r.id}>
                <td>{r.label}</td>
                <td>{r.avgMs} ms</td>
                <td>{r.p95Ms} ms</td>
                <td>≤ {r.targetMs} ms</td>
                <td>
                  <StatusBadge status={r.pass ? "ok" : "fail"} />
                </td>
                <td className="meta">{r.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
