import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureSprint5Evidence } from "@/server/performance/dashboard";
import { latestPerfRun } from "@/server/performance/store";
import { actionRunLoadTests } from "@/server/performance/actions";
import type { LoadTestResult } from "@/server/performance/load-test";

export default async function LoadTestsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.observability.read") && actor !== "admin@goldmind.local") {
    redirect("/portal/admin");
  }
  await ensureSprint5Evidence();
  const run = latestPerfRun("load");
  const payload = run?.payload as { results: LoadTestResult[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.observability.write") || actor === "admin@goldmind.local";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Load Testing</h1>
        <p className="page-sub">Portal · Auth · License · Payments · Support · Admin · Cloud · score {payload?.score ?? "—"}</p>
      </header>
      {canWrite && (
        <form action={actionRunLoadTests} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run load tests
          </button>
        </form>
      )}
      <div className="stack">
        {(payload?.results || []).map((r) => (
          <div className="card" key={r.target}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{r.label}</strong>
              <StatusBadge status={r.pass ? "ok" : "fail"} />
              {r.bottleneck ? <StatusBadge status={r.bottleneck} /> : null}
            </div>
            <p className="meta">
              {r.requests} req · concurrency {r.concurrency} · avg {r.avgMs}ms · p95 {r.p95Ms}ms · p99 {r.p99Ms}ms ·
              success {r.successRate}%
            </p>
            <p>{r.recommendation}</p>
          </div>
        ))}
      </div>
    </>
  );
}
