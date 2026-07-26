import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getPartnerByEmail, getPartnerPortalDashboard } from "@/server/partners/portal";

export default async function PartnerCommissionsPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const partner = getPartnerByEmail(session.user.email);
  if (!partner) redirect("/portal/partner");
  const dash = getPartnerPortalDashboard(partner.id)!;

  return (
    <>
      <h1 className="page-title">Commission History & Payouts</h1>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Type</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Created</th>
            </tr>
          </thead>
          <tbody>
            {dash.commissionSummary.history.map((c) => (
              <tr key={c.id}>
                <td className="meta">{c.id}</td>
                <td>{c.type}</td>
                <td>USD {(c.amountCents / 100).toFixed(2)}</td>
                <td>{c.status}</td>
                <td className="meta">{c.createdAt.slice(0, 10)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <h2 style={{ fontSize: 16 }}>Payout Status</h2>
      <ul>
        {dash.payoutStatus.length === 0 ? (
          <li className="meta">No payout requests</li>
        ) : (
          dash.payoutStatus.map((p) => (
            <li key={p.id}>
              {p.id} · USD {(p.amountCents / 100).toFixed(2)} · {p.status}
            </li>
          ))
        )}
      </ul>
      <p style={{ marginTop: 16 }}>
        <Link className="btn" href="/portal/partner">
          Dashboard
        </Link>
      </p>
    </>
  );
}
