import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { getAdminSecurityPolicy } from "@/server/admin/security";
import { actionConfirmSensitive, actionIssueConfirmToken } from "@/server/admin/actions";
import { listAudit } from "@/server/cloud/audit";

export default async function AdminSecurityPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.security.manage") && actor !== "admin@goldmind.local") redirect("/portal");

  const policy = getAdminSecurityPolicy();
  const secEvents = listAudit(20).filter((e) => e.meta?.security === "1" || e.detail?.includes("confirm"));

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Administration Security</h1>
        <p className="page-sub">
          Session timeout · 2FA architecture · IP logging · permission validation · sensitive confirmations
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Admin Session Timeout</h3>
          <div className="value">{policy.idleTimeoutMinutes}m</div>
          <div className="meta">Max session {policy.sessionMaxHours}h</div>
        </div>
        <div className="card">
          <h3>Two-Factor Auth</h3>
          <div className="meta">{policy.twoFactor.status}</div>
          <div className="meta">Providers: {policy.twoFactor.providers.join(", ")}</div>
          <div className="meta">Enforced roles: {policy.twoFactor.enforcedForRoles.join(", ")}</div>
        </div>
        <div className="card">
          <h3>Controls</h3>
          <div className="meta">IP logging: {String(policy.ipLogging)}</div>
          <div className="meta">Permission validation: {String(policy.permissionValidation)}</div>
          <div className="meta">Sensitive confirm: {String(policy.sensitiveActionConfirmation)}</div>
          <div className="meta">TE access: {String(policy.tradingEngineAccess)}</div>
        </div>
      </div>

      <div id="2fa" className="card" style={{ marginBottom: 16 }}>
        <h3>2FA architecture</h3>
        <p style={{ margin: "8px 0" }}>{policy.twoFactor.note}</p>
        <p className="meta">Enrollment path: {policy.twoFactor.enrollmentPath}</p>
        <p className="meta">Recovery codes: {String(policy.twoFactor.recoveryCodes)}</p>
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Sensitive action confirmation</h3>
        <form action={actionIssueConfirmToken} style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 8 }}>
          <input type="hidden" name="action" value="demo_sensitive" />
          <button type="submit" className="btn">
            Issue confirm token (demo)
          </button>
        </form>
        <form action={actionConfirmSensitive} style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 8 }}>
          <input type="hidden" name="action" value="demo_sensitive" />
          <input name="token" placeholder="Paste confirm token" style={{ minWidth: 240 }} />
          <button type="submit" className="btn btn-primary">
            Confirm sensitive action
          </button>
        </form>
      </div>

      <h2 style={{ fontSize: 16 }}>Security event log</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>When</th>
              <th>User</th>
              <th>Detail</th>
              <th>Result</th>
            </tr>
          </thead>
          <tbody>
            {secEvents.length === 0 && (
              <tr>
                <td colSpan={4}>No security events yet</td>
              </tr>
            )}
            {secEvents.map((e) => (
              <tr key={e.id}>
                <td>{e.at.slice(0, 19).replace("T", " ")}</td>
                <td>{e.user}</td>
                <td>{e.detail}</td>
                <td>{e.result}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
