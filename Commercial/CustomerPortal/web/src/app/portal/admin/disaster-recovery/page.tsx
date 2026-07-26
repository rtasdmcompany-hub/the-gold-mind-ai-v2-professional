import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint6Evidence } from "@/server/security/dashboard";
import { latestSecurityRun } from "@/server/security/store";
import { actionRunDr } from "@/server/security/actions";
import type { DrCheck } from "@/server/security/disaster-recovery";

export default async function DisasterRecoveryPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.security.manage") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint6Evidence();
  const payload = latestSecurityRun("disaster_recovery")?.payload as
    | { checks: DrCheck[]; score: number; lastDrill?: { id: string; bytes: number; restoreOk: boolean } }
    | undefined;
  const canWrite = hasPermission(role, "admin.security.manage") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Backup & Disaster Recovery</h1>
        <p className="page-sub">
          Score {payload?.score ?? "—"}
          {payload?.lastDrill
            ? ` · last drill ${payload.lastDrill.id} · ${payload.lastDrill.bytes} bytes · restore ${payload.lastDrill.restoreOk ? "OK" : "FAIL"}`
            : ""}
        </p>
      </header>
      {canWrite && (
        <form action={actionRunDr} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Run DR drill
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Check</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.checks || []).map((c) => (
              <tr key={c.id}>
                <td>{c.label}</td>
                <td>
                  <StatusBadge status={c.status} />
                </td>
                <td className="meta">{c.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
