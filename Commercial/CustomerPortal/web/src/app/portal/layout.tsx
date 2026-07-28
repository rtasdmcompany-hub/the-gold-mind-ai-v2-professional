import { auth } from "@/auth";
import Link from "next/link";
import { PortalNav } from "@/components/PortalNav";
import { PortalUserBar } from "@/components/PortalUserBar";
import { BrandLogo, RtasGroupBadge } from "@/components/BrandLogo";
import { canAccessAdminConsole } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { redirect } from "next/navigation";

export default async function PortalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await auth();
  if (!session?.user) redirect("/login");
  const role = (session.user as { role?: string }).role;
  const showAdmin = canAccessAdminConsole(role) || isDevAdminBypass(session.user.email);

  return (
    <div className="shell portal-shell">
      <PortalNav showAdmin={!!showAdmin} />
      <div className="main">
        <div className="portal-site-bar">
          <Link href="/" className="portal-site-bar-brand">
            THE GOLD MIND AI · Official Website
          </Link>
          <div className="portal-site-bar-links">
            <Link href="/">Home</Link>
            <Link href="/pricing">Pricing</Link>
            <Link href="/docs">Docs</Link>
            <Link href="/contact">Contact</Link>
          </div>
        </div>
        <div className="topbar portal-topbar">
          <PortalUserBar
            name={session.user.name}
            email={session.user.email}
            image={session.user.image}
            role={role}
          />
        </div>
        {children}
        <footer className="portal-footer-block">
          <div className="portal-footer-brands">
            <BrandLogo variant="footer" href="/" />
            <RtasGroupBadge height={44} />
          </div>
          <p className="footer-note">
            THE GOLD MIND AI v2.0 PROFESSIONAL · Customer Portal · Commercial service only · Core Trading Engine is not
            connected to this application.
          </p>
          <div className="portal-footer-links">
            <Link href="/">← Back to Official Website</Link>
            <Link href="/privacy">Privacy</Link>
            <Link href="/terms">Terms</Link>
            <Link href="/contact">Support</Link>
          </div>
        </footer>
      </div>
    </div>
  );
}

