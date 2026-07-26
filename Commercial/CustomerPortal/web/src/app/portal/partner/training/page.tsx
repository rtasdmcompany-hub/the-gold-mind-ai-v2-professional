import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getPartnerByEmail, getPartnerPortalDashboard } from "@/server/partners/portal";

export default async function PartnerTrainingPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const partner = getPartnerByEmail(session.user.email);
  if (!partner) redirect("/portal/partner");
  const dash = getPartnerPortalDashboard(partner.id)!;

  return (
    <>
      <h1 className="page-title">Training Center</h1>
      <ul>
        {dash.training.map((t) => (
          <li key={t.id}>
            <Link href={t.path}>{t.title}</Link>
          </li>
        ))}
      </ul>
      <div className="card" style={{ marginTop: 16 }}>
        <h3>Support Center</h3>
        <p>
          Email: {dash.support.email} ·{" "}
          <Link href={dash.support.portalPath}>Portal support</Link>
        </p>
      </div>
      <p style={{ marginTop: 16 }}>
        <Link className="btn" href="/portal/partner">
          Dashboard
        </Link>
      </p>
    </>
  );
}
