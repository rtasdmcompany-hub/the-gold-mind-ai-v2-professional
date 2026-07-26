import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint5Dashboard } from "@/server/i18n/suite";
import { actionRunI18nSuite } from "@/server/i18n/actions";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";

export default async function LocalizationAdminPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint5Dashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20, display: "flex", justifyContent: "space-between", gap: 16, flexWrap: "wrap" }}>
        <div>
          <h1 className="page-title">Localization</h1>
          <p className="page-sub">Phase 11 Sprint 5 · multilingual commercial platform</p>
        </div>
        <LanguageSwitcher current="en" />
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Localization</h3>
          <div className="value">{dash.localizationScore}</div>
        </div>
        <div className="card">
          <h3>International Readiness</h3>
          <div className="value">{dash.internationalReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Translation Quality</h3>
          <div className="value">{dash.translationQualityScore}</div>
        </div>
        <div className="card">
          <h3>Regional Expansion</h3>
          <div className="value">{dash.regionalExpansionScore}</div>
        </div>
        <div className="card">
          <h3>Compliance</h3>
          <div className="value">{dash.complianceScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunI18nSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh localization suite
          </button>
        </form>
      )}

      <h2 style={{ fontSize: 16 }}>Language packs ({dash.masterKeyCount} master keys)</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Code</th>
              <th>Version</th>
              <th>Direction</th>
              <th>Translated %</th>
              <th>Missing</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {dash.status.rows.map((row) => (
              <tr key={row.locale}>
                <td>{row.locale}</td>
                <td>{row.version}</td>
                <td>{dash.locales.find((l) => l.code === row.locale)?.direction || "—"}</td>
                <td>{row.percent}%</td>
                <td>{row.missing}</td>
                <td>{row.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Regional profiles</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Region</th>
              <th>Language</th>
              <th>Timezone</th>
              <th>Currency</th>
              <th>Measurement</th>
              <th>Sample</th>
            </tr>
          </thead>
          <tbody>
            {dash.regional.map((r) => (
              <tr key={r.code}>
                <td>{r.code}</td>
                <td>{r.settings.language}</td>
                <td>{r.settings.timezone}</td>
                <td>{r.settings.currency}</td>
                <td>{r.settings.measurement}</td>
                <td>
                  {r.preview.sampleCurrency} · {r.preview.dir}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/localization-qa">
          Localization QA
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 6.
      </p>
    </>
  );
}
