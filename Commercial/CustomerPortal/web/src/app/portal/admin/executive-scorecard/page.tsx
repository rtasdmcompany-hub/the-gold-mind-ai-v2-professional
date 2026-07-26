import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint9Evidence } from "@/server/executive/dashboard";
import { getExecutiveGoNoGoDashboard } from "@/server/executive/dashboard";

export default async function ExecutiveScorecardPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  await ensureSprint9Evidence();
  const dash = await getExecutiveGoNoGoDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Scorecard</h1>
        <p className="page-sub">Overall project {dash.overallProjectScore}</p>
      </header>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Area</th>
              <th>Score</th>
            </tr>
          </thead>
          <tbody>
            {dash.scorecardRows.map((r) => (
              <tr key={r.area}>
                <td>{r.area}</td>
                <td>{r.score}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
