import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureSprint5Evidence } from "@/server/performance/dashboard";
import { latestPerfRun } from "@/server/performance/store";
import { actionRunScalability } from "@/server/performance/actions";
import type { ScalabilityPoint } from "@/server/performance/scalability";

export default async function ScalabilityPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.observability.read")) {
    redirect("/portal/admin");
  }
  await ensureSprint5Evidence();
  const run = latestPerfRun("scalability");
  const payload = run?.payload as { points: ScalabilityPoint[]; score: number; cacheBackend: string } | undefined;
  const canWrite = hasPermission(role, "admin.observability.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Scalability Testing</h1>
        <p className="page-sub">
          100 → 5,000 concurrent users (capacity model + measured unit work) · score {payload?.score ?? "—"} · cache{" "}
          {payload?.cacheBackend}
        </p>
      </header>
      {canWrite && (
        <form action={actionRunScalability} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run scalability suite
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Users</th>
              <th>Avg</th>
              <th>P95</th>
              <th>Success</th>
              <th>CPU</th>
              <th>Mem</th>
              <th>DB</th>
              <th>Redis</th>
              <th>Workers</th>
              <th>Pass</th>
              <th>Bottlenecks</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.points || []).map((p) => (
              <tr key={p.concurrentUsers}>
                <td>{p.concurrentUsers}</td>
                <td>{p.avgResponseMs} ms</td>
                <td>{p.p95ResponseMs} ms</td>
                <td>{p.successRate}%</td>
                <td>{p.cpuUsagePct}%</td>
                <td>{p.memoryUsageMb} MB</td>
                <td>{p.databaseMs} ms</td>
                <td>{p.redisMs} ms</td>
                <td>{p.workersOk ? "ok" : "fail"}</td>
                <td>
                  <StatusBadge status={p.pass ? "ok" : "watch"} />
                </td>
                <td className="meta">{p.bottlenecks.join(", ") || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
