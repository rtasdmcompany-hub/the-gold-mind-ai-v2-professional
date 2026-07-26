import { auth } from "@/auth";
import { SignOutButton } from "@/components/SignOutButton";

export default async function SecurityPage() {
  const session = await auth();
  const googleEnabled = !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);
  const role = (session?.user as { role?: string } | undefined)?.role || "customer";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Security</h1>
        <p className="page-sub">Session, OAuth, roles, and secure logout.</p>
      </header>

      <div className="grid grid-2">
        <div className="card">
          <h3>Authentication</h3>
          <p style={{ margin: "8px 0 0" }}>
            Google OAuth: {googleEnabled ? "Configured" : "Not configured (Demo Sign-In active)"}
          </p>
          <p className="meta">Session strategy: JWT · max age 8 hours</p>
        </div>
        <div className="card">
          <h3>Role-based access (foundation)</h3>
          <p style={{ margin: "8px 0 0" }}>
            Current role: <strong>{role}</strong>
          </p>
          <p className="meta">Roles reserved: customer · admin (admin routes deferred)</p>
        </div>
        <div className="card">
          <h3>Protected routes</h3>
          <p style={{ margin: "8px 0 0" }}>
            All <code>/portal/*</code> paths require a valid session via middleware.
          </p>
        </div>
        <div className="card">
          <h3>Secure logout</h3>
          <p style={{ margin: "8px 0 12px" }}>Ends the portal session and returns to login.</p>
          <SignOutButton />
        </div>
      </div>
    </>
  );
}
