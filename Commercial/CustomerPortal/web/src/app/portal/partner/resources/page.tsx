import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getPartnerByEmail, getPartnerPortalDashboard } from "@/server/partners/portal";

export default async function PartnerResourcesPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const partner = getPartnerByEmail(session.user.email);
  if (!partner) redirect("/portal/partner");
  const dash = getPartnerPortalDashboard(partner.id)!;

  return (
    <>
      <h1 className="page-title">Marketing Assets</h1>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Resource</th>
              <th>Category</th>
              <th>Status</th>
              <th>Path</th>
            </tr>
          </thead>
          <tbody>
            {dash.resources.map((r) => (
              <tr key={r.id}>
                <td>{r.title}</td>
                <td>{r.category}</td>
                <td>{r.status}</td>
                <td className="meta">{r.path}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p style={{ marginTop: 16 }}>
        <Link className="btn" href="/portal/partner">
          Dashboard
        </Link>
      </p>
    </>
  );
}
