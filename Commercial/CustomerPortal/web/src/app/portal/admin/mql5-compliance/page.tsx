import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint7Evidence } from "@/server/market/dashboard";
import { latestMarketRun } from "@/server/market/store";
import { actionRunCompliance } from "@/server/market/actions";
import type { ComplianceItem, ScanHit } from "@/server/market/compliance";

export default async function Mql5CompliancePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.releases.read") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint7Evidence();
  const payload = latestMarketRun("compliance")?.payload as
    | { items: ComplianceItem[]; scanHits: ScanHit[]; score: number }
    | undefined;
  const canWrite = hasPermission(role, "admin.releases.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">MQL5 Compliance Review</h1>
        <p className="page-sub">Score {payload?.score ?? "—"} · Core scanned read-only</p>
      </header>
      {canWrite && (
        <form action={actionRunCompliance} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run compliance
          </button>
        </form>
      )}
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Requirement</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.items || []).map((i) => (
              <tr key={i.id}>
                <td>{i.requirement}</td>
                <td>
                  <StatusBadge status={i.status} />
                </td>
                <td className="meta">{i.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <h2 style={{ fontSize: 16 }}>String scan hits</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>File</th>
              <th>Pattern</th>
              <th>Line</th>
              <th>Excerpt</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.scanHits || []).length === 0 ? (
              <tr>
                <td colSpan={4}>No forbidden payment/guarantee patterns in Market package scan</td>
              </tr>
            ) : (
              (payload?.scanHits || []).map((h, idx) => (
                <tr key={`${h.file}-${h.line}-${idx}`}>
                  <td>{h.file}</td>
                  <td>{h.pattern}</td>
                  <td>{h.line}</td>
                  <td className="meta">{h.excerpt}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </>
  );
}
