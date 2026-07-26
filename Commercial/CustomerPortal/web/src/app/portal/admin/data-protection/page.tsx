import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint6Evidence } from "@/server/security/dashboard";
import { latestSecurityRun } from "@/server/security/store";
import { actionRunDataProtection } from "@/server/security/actions";
import type { DataProtectionCheck } from "@/server/security/data-protection";

export default async function DataProtectionPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.security.manage") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint6Evidence();
  const payload = latestSecurityRun("data_protection")?.payload as
    | { checks: DataProtectionCheck[]; score: number }
    | undefined;
  const canWrite = hasPermission(role, "admin.security.manage") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Data Protection</h1>
        <p className="page-sub">Score {payload?.score ?? "—"}</p>
      </header>
      {canWrite && (
        <form action={actionRunDataProtection} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run data protection review
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Control</th>
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
