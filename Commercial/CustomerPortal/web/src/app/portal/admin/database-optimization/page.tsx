import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureSprint5Evidence } from "@/server/performance/dashboard";
import { latestPerfRun } from "@/server/performance/store";
import { actionRunDbReview } from "@/server/performance/actions";
import type { DbOptimizationFinding } from "@/server/performance/database-optimization";

export default async function DatabaseOptimizationPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.observability.read") && actor !== "admin@goldmind.local") {
    redirect("/portal/admin");
  }
  await ensureSprint5Evidence();
  const run = latestPerfRun("database");
  const payload = run?.payload as { findings: DbOptimizationFinding[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.observability.write") || actor === "admin@goldmind.local";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Database Optimization</h1>
        <p className="page-sub">Indexes · slow queries · pooling · caching · migrations · backups · score {payload?.score ?? "—"}</p>
      </header>
      {canWrite && (
        <form action={actionRunDbReview} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run review
          </button>
        </form>
      )}
      <div className="stack">
        {(payload?.findings || []).map((f) => (
          <div className="card" key={f.area}>
            <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <strong>{f.area}</strong>
              <StatusBadge status={f.status} />
            </div>
            <p className="meta">{f.detail}</p>
            <p>{f.recommendation}</p>
          </div>
        ))}
      </div>
    </>
  );
}
