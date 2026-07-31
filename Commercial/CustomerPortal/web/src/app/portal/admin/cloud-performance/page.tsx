import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureSprint5Evidence } from "@/server/performance/dashboard";
import { latestPerfRun } from "@/server/performance/store";
import { actionRunCloudValidation } from "@/server/performance/actions";
import type { CloudCheck } from "@/server/performance/cloud-performance";

export default async function CloudPerformancePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.observability.read")) {
    redirect("/portal/admin");
  }
  await ensureSprint5Evidence();
  const run = latestPerfRun("cloud");
  const payload = run?.payload as { checks: CloudCheck[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.observability.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Cloud Performance</h1>
        <p className="page-sub">
          Cloudflare · Supabase · RunPod · Upstash · Email · Storage · API Gateway · score {payload?.score ?? "—"}
        </p>
      </header>
      {canWrite && (
        <form action={actionRunCloudValidation} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-validate cloud
          </button>
        </form>
      )}
      <div className="stack">
        {(payload?.checks || []).map((c) => (
          <div className="card" key={c.id}>
            <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <strong>{c.label}</strong>
              <StatusBadge status={c.status} />
              {typeof c.latencyMs === "number" ? <span className="meta">{c.latencyMs} ms</span> : null}
            </div>
            <p className="meta">{c.detail}</p>
            <p>{c.recommendation}</p>
          </div>
        ))}
      </div>
    </>
  );
}
