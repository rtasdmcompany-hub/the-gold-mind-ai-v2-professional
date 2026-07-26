import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint6Evidence } from "@/server/security/dashboard";
import { latestSecurityRun } from "@/server/security/store";
import { actionRunSecrets } from "@/server/security/actions";
import type { SecretCheck } from "@/server/security/secrets-review";

export default async function SecretManagementPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.security.manage") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint6Evidence();
  const payload = latestSecurityRun("secrets")?.payload as { checks: SecretCheck[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.security.manage") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Secret & Key Management</h1>
        <p className="page-sub">Score {payload?.score ?? "—"} · never commit live secrets</p>
      </header>
      {canWrite && (
        <form action={actionRunSecrets} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run secrets review
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
