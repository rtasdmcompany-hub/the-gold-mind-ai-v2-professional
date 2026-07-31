import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { getRolePermissionMatrix, hasPermission, ROLE_LABELS } from "@/server/admin/roles";

export default async function AdminRolesPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.roles.manage")) redirect("/portal");

  const matrix = getRolePermissionMatrix();
  const allPerms = Array.from(new Set(matrix.flatMap((m) => m.permissions))).sort();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Role Permission Matrix</h1>
        <p className="page-sub">
          Super Administrator · Commercial Manager · Support Agent · Finance Manager · QA Manager · Read-only Auditor
        </p>
      </header>

      <div className="table-wrap" style={{ overflowX: "auto" }}>
        <table className="data">
          <thead>
            <tr>
              <th>Permission</th>
              {matrix.map((m) => (
                <th key={m.role}>{ROLE_LABELS[m.role]}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {allPerms.map((p) => (
              <tr key={p}>
                <td className="mono">{p}</td>
                {matrix.map((m) => (
                  <td key={m.role}>{m.permissions.includes(p) ? "✓" : "—"}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p className="meta" style={{ marginTop: 16 }}>
        Assign via env: PORTAL_SUPER_ADMIN_EMAILS · PORTAL_COMMERCIAL_MANAGER_EMAILS · PORTAL_SUPPORT_EMAILS ·
        PORTAL_FINANCE_EMAILS · PORTAL_QA_EMAILS · PORTAL_AUDITOR_EMAILS
      </p>
    </>
  );
}
