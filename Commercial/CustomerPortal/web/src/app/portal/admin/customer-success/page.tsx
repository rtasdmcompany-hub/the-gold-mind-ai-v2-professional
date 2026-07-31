import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import {
  getCustomerHealth,
  getCustomerSuccessSummary,
  listCustomerHealthDirectory,
} from "@/server/success/customer-health";

export default async function CustomerSuccessCenterPage({
  searchParams,
}: {
  searchParams: Promise<{ email?: string; q?: string }>;
}) {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (
    !hasPermission(role, "admin.support.read") &&
    !hasPermission(role, "admin.launch.read")
  ) {
    redirect("/portal/admin");
  }

  const sp = await searchParams;
  const summary = getCustomerSuccessSummary();
  const directory = listCustomerHealthDirectory(sp.q);
  const selected = sp.email ? getCustomerHealth(sp.email) : null;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Customer Success Center</h1>
        <p className="page-sub">
          Health · onboarding · activation · licenses · support · KB suggestions · satisfaction timeline
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Customers tracked</h3>
          <div className="value">{summary.customersTracked}</div>
        </div>
        <div className="card">
          <h3>Avg health</h3>
          <div className="value">{summary.avgHealthScore}</div>
        </div>
        <div className="card">
          <h3>At risk</h3>
          <div className="value">{summary.atRisk}</div>
          <div className="meta">Activated {summary.activated}</div>
        </div>
      </div>

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", gap: 12 }}>
        <div className="field">
          <label htmlFor="q">Search customers</label>
          <input id="q" name="q" defaultValue={sp.q || ""} />
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
      </form>

      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Health</th>
              <th>Onboarding</th>
              <th>Activation</th>
              <th>License</th>
              <th>Tickets</th>
            </tr>
          </thead>
          <tbody>
            {directory.map((c) => (
              <tr key={c.email}>
                <td>
                  <Link href={`/portal/admin/customer-success?email=${encodeURIComponent(c.email)}`}>
                    {c.name}
                  </Link>
                  <div className="meta">{c.email}</div>
                </td>
                <td>{c.healthScore}</td>
                <td>{c.onboardingPct}%</td>
                <td>
                  <StatusBadge status={c.activationStatus} />
                </td>
                <td>
                  <StatusBadge status={c.licenseStatus} />
                </td>
                <td>{c.openTickets}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selected && (
        <div className="card">
          <h3>
            {selected.name} · health {selected.healthScore}
          </h3>
          <p className="meta">
            Onboarding {selected.onboardingPct}% · Activation {selected.activationStatus} · Licenses{" "}
            {selected.activeLicenses} ({selected.licenseStatus}) · Subscription {selected.subscriptionStatus}
          </p>
          <h4 style={{ marginTop: 12 }}>Support history</h4>
          <ul>
            {selected.supportHistory.length === 0 && <li className="meta">No tickets</li>}
            {selected.supportHistory.map((t) => (
              <li key={t.id}>
                {t.subject} · <StatusBadge status={t.status} /> · {t.updatedAt}
              </li>
            ))}
          </ul>
          <h4>KB suggestions</h4>
          <ul>
            {selected.kbSuggestions.map((k) => (
              <li key={k.slug}>
                <Link href={`/portal/knowledge-base?slug=${k.slug}`}>{k.title}</Link>{" "}
                <span className="meta">({k.category})</span>
              </li>
            ))}
          </ul>
          <h4>Satisfaction timeline</h4>
          <ul>
            {selected.satisfactionTimeline.length === 0 && <li className="meta">No scores yet</li>}
            {selected.satisfactionTimeline.map((s, i) => (
              <li key={`${s.at}-${i}`}>
                ★ {s.score}/5 · {s.title} · {s.at}
              </li>
            ))}
          </ul>
        </div>
      )}
    </>
  );
}
