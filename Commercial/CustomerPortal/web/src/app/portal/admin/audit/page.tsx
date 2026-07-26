import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { listAudit } from "@/server/cloud/audit";
import type { AuditAction } from "@/server/cloud/types";
import { writeAudit } from "@/server/cloud/audit";

const ACTIONS: AuditAction[] = [
  "login",
  "logout",
  "login_failed",
  "license_activation",
  "payment_event",
  "device_registration",
  "profile_change",
  "admin_action",
  "download",
  "update",
  "support_action",
  "api_request",
  "rate_limited",
  "health_check",
];

export default async function AdminAuditCenterPage({
  searchParams,
}: {
  searchParams: Promise<{ action?: string; user?: string; export?: string }>;
}) {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.audit.read") && actor !== "admin@goldmind.local") redirect("/portal");

  const sp = await searchParams;
  const action = (sp.action || "") as AuditAction | "";
  const user = sp.user || "";
  const entries = listAudit(200, {
    action: action || undefined,
    user: user || undefined,
  });

  const canExport = hasPermission(role, "admin.audit.export") || actor === "admin@goldmind.local";
  if (sp.export === "1" && canExport) {
    writeAudit({
      user: actor,
      action: "admin_action",
      ip: "admin",
      result: "success",
      detail: `audit export ${entries.length} rows`,
    });
  }

  const csv = entries
    .map((e) =>
      [e.at, e.user, e.action, e.ip, e.result, JSON.stringify(e.detail || "")].join(",")
    )
    .join("\n");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Audit Center</h1>
        <p className="page-sub">
          Login · license · payment · admin · support · downloads · updates · customer changes — filter &amp; export
        </p>
      </header>

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div className="field">
          <label htmlFor="action">Action</label>
          <select id="action" name="action" defaultValue={action}>
            <option value="">All</option>
            {ACTIONS.map((a) => (
              <option key={a} value={a}>
                {a}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="user">User</label>
          <input id="user" name="user" defaultValue={user} placeholder="email" />
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
        {canExport && (
          <button type="submit" name="export" value="1" className="btn" style={{ alignSelf: "flex-end" }}>
            Prepare export
          </button>
        )}
      </form>

      {sp.export === "1" && canExport && (
        <div className="card" style={{ marginBottom: 16 }}>
          <h3>CSV export</h3>
          <p className="meta">Copy below (timestamp,user,action,ip,result,detail)</p>
          <textarea readOnly rows={8} style={{ width: "100%", fontFamily: "monospace", fontSize: 12 }} value={`at,user,action,ip,result,detail\n${csv}`} />
        </div>
      )}

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>When</th>
              <th>User</th>
              <th>Action</th>
              <th>IP</th>
              <th>Result</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((e) => (
              <tr key={e.id}>
                <td>{e.at.slice(0, 19).replace("T", " ")}</td>
                <td>{e.user}</td>
                <td className="mono">{e.action}</td>
                <td className="mono">{e.ip}</td>
                <td>
                  <StatusBadge status={e.result} />
                </td>
                <td>{e.detail || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
