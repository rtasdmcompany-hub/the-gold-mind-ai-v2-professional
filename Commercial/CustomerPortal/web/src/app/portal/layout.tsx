import { auth } from "@/auth";
import { PortalNav } from "@/components/PortalNav";
import { SignOutButton } from "@/components/SignOutButton";
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
    <div className="shell">
      <PortalNav showAdmin={!!showAdmin} />
      <div className="main">
        <div className="topbar">
          <div>
            <div className="page-sub" style={{ margin: 0 }}>
              Signed in as {session.user.name || session.user.email}
              {role ? ` · role: ${role}` : ""}
            </div>
          </div>
          <SignOutButton />
        </div>
        {children}
        <p className="footer-note">
          THE GOLD MIND PROFESSIONAL · Customer Portal · Commercial service only · Core Trading Engine is not connected
          to this application.
        </p>
      </div>
    </div>
  );
}
