import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint6Evidence } from "@/server/security/dashboard";
import { latestSecurityRun } from "@/server/security/store";
import { actionRunCompliance } from "@/server/security/actions";
import type { ComplianceItem } from "@/server/security/compliance";

export default async function CompliancePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.security.manage") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint6Evidence();
  const payload = latestSecurityRun("compliance")?.payload as { items: ComplianceItem[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.security.manage") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Compliance Review</h1>
        <p className="page-sub">Score {payload?.score ?? "—"} · BC-LEGAL still Owner/counsel gated</p>
      </header>
      {canWrite && (
        <form action={actionRunCompliance} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run compliance review
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Item</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.items || []).map((i) => (
              <tr key={i.id}>
                <td>{i.label}</td>
                <td>
                  <StatusBadge status={i.status} />
                </td>
                <td className="meta">{i.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
