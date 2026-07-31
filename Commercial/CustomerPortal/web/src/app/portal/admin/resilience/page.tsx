import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureSprint5Evidence } from "@/server/performance/dashboard";
import { latestPerfRun } from "@/server/performance/store";
import { actionRunResilience } from "@/server/performance/actions";
import type { ResilienceDrill } from "@/server/performance/resilience";

export default async function ResiliencePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.observability.read")) {
    redirect("/portal/admin");
  }
  await ensureSprint5Evidence();
  const run = latestPerfRun("resilience");
  const payload = run?.payload as { drills: ResilienceDrill[]; score: number; gracefulDegradation: boolean } | undefined;
  const canWrite = hasPermission(role, "admin.observability.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Production Resilience</h1>
        <p className="page-sub">
          Score {payload?.score ?? "—"} · graceful degradation{" "}
          {payload?.gracefulDegradation ? "YES" : "NO"} · Core continues if commercial services fail
        </p>
      </header>
      {canWrite && (
        <form action={actionRunResilience} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run resilience drills
          </button>
        </form>
      )}
      <div className="stack">
        {(payload?.drills || []).map((d) => (
          <div className="card" key={d.id}>
            <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <strong>{d.label}</strong>
              <StatusBadge status={d.passed ? "ok" : "fail"} />
              {typeof d.recoveryMs === "number" ? <span className="meta">{d.recoveryMs} ms</span> : null}
            </div>
            <p className="meta">{d.detail}</p>
          </div>
        ))}
      </div>
    </>
  );
}
