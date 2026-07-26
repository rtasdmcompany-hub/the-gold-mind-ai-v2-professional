import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint6Evidence } from "@/server/security/dashboard";
import { latestSecurityRun } from "@/server/security/store";
import { actionRunOwasp } from "@/server/security/actions";
import type { OwaspItem } from "@/server/security/owasp";

export default async function OwaspPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.security.manage") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint6Evidence();
  const payload = latestSecurityRun("owasp")?.payload as { items: OwaspItem[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.security.manage") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">OWASP Top 10 Review</h1>
        <p className="page-sub">Score {payload?.score ?? "—"} · commercial portal applicability</p>
      </header>
      {canWrite && (
        <form action={actionRunOwasp} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run OWASP review
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Category</th>
              <th>Risk</th>
              <th>Mitigation</th>
              <th>Result</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.items || []).map((i) => (
              <tr key={i.id}>
                <td>{i.id}</td>
                <td>{i.category}</td>
                <td className="meta">{i.risk}</td>
                <td className="meta">{i.mitigation}</td>
                <td>
                  <StatusBadge status={i.verification} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
