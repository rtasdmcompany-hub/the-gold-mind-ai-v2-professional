import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase12Dashboard } from "@/server/phase12/suite";

export default async function Phase12MonthlyPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase12Dashboard();
  const monthly = dash.monthly as { files?: string[]; month?: string; scores?: typeof dash.scores } | null;
  const files = monthly?.files || [
    "PHASE12_CUSTOMER_SUCCESS_REPORT.md",
    "PHASE12_COMMERCIAL_REPORT.md",
    "PHASE12_INFRASTRUCTURE_REPORT.md",
    "PHASE12_SECURITY_REPORT.md",
    "PHASE12_SUPPORT_REPORT.md",
    "PHASE12_PERFORMANCE_REPORT.md",
    "PHASE12_FINANCIAL_DASHBOARD.md",
    "PHASE12_ENTERPRISE_SCORECARD.md",
  ];

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Phase 12 — Monthly Executive Pack</h1>
        <p className="page-sub">
          Customer · Commercial · Infra · Security · Support · Performance · Financial · Scorecard
        </p>
      </header>

      <p className="meta" style={{ marginBottom: 16 }}>
        Month: {monthly?.month || "current"} · Overall health {dash.scores.overallPlatformHealth} ·{" "}
        <Link href="/portal/admin/phase12-lts">LTS Hub</Link>
      </p>

      <ul>
        {files.map((f) => (
          <li key={f}>
            <code>{f}</code>
          </li>
        ))}
      </ul>

      <div className="table-wrap" style={{ marginTop: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Score</th>
              <th>Value</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Customer Success</td>
              <td>{dash.scores.customerSuccessScore}</td>
            </tr>
            <tr>
              <td>Support</td>
              <td>{dash.scores.supportScore}</td>
            </tr>
            <tr>
              <td>Business Growth</td>
              <td>{dash.scores.businessGrowthScore}</td>
            </tr>
            <tr>
              <td>Operational Excellence</td>
              <td>{dash.scores.operationalExcellenceScore}</td>
            </tr>
            <tr>
              <td>Infrastructure Health</td>
              <td>{dash.scores.infrastructureHealth}</td>
            </tr>
            <tr>
              <td>Overall Platform Health</td>
              <td>{dash.scores.overallPlatformHealth}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </>
  );
}
