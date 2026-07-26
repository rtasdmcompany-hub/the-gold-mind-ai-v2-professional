import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint5Dashboard } from "@/server/i18n/suite";

export default async function LocalizationQaPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint5Dashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Localization QA</h1>
        <p className="page-sub">
          Completeness · RTL · unicode · encoding · average {dash.qa.averageCompleteness}%
        </p>
      </header>

      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Locale</th>
              <th>Completeness</th>
              <th>Missing</th>
              <th>RTL</th>
              <th>Unicode</th>
              <th>Encoding</th>
              <th>Layout</th>
              <th>Plural sample</th>
            </tr>
          </thead>
          <tbody>
            {dash.qa.locales.map((l) => (
              <tr key={l.code}>
                <td>{l.code}</td>
                <td>{l.completeness}%</td>
                <td>{l.missingCount}</td>
                <td>{l.rtlRenderOk ? "pass" : "fail"}</td>
                <td>{l.unicodeOk ? "pass" : "fail"}</td>
                <td>{l.encoding}</td>
                <td>{l.layoutIntegrity}</td>
                <td>{l.samples.pluralOther}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Compliance checks ({dash.compliance.score})</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Check</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {dash.compliance.checks.map((c) => (
              <tr key={c.id}>
                <td>{c.label}</td>
                <td>{c.status}</td>
                <td>{c.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Translation reviews</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Locale</th>
              <th>Key</th>
              <th>Status</th>
              <th>Updated</th>
            </tr>
          </thead>
          <tbody>
            {dash.status.reviews.slice(0, 20).map((r) => (
              <tr key={r.id}>
                <td>{r.locale}</td>
                <td>{r.key}</td>
                <td>{r.status}</td>
                <td>{r.updatedAt.slice(0, 19)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/localization">
          Back to Localization
        </Link>
      </p>
    </>
  );
}
