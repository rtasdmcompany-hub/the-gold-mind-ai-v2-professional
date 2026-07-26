import type { Metadata } from "next";
import Link from "next/link";
import { SiteNav } from "@/components/SiteNav";
import { SiteFooter } from "@/components/SiteFooter";

export const metadata: Metadata = {
  title: "Register — THE GOLD MIND PROFESSIONAL",
  description: "Invite-only registration for THE GOLD MIND PROFESSIONAL Controlled Launch.",
};

export default async function RegisterPage({
  searchParams,
}: {
  searchParams: Promise<{ invite?: string }>;
}) {
  const sp = await searchParams;
  const invite = (sp.invite || "").trim();
  const openSignup = process.env.PORTAL_OPEN_SIGNUP === "true";

  return (
    <div>
      <SiteNav />
      <main style={{ maxWidth: 520, margin: "0 auto", padding: "48px 24px 80px" }}>
        <p className="brand-mark">THE GOLD MIND PROFESSIONAL</p>
        <h1 style={{ fontFamily: "Georgia, serif", fontSize: 36, fontWeight: 400 }}>Create account</h1>
        {!openSignup && !invite ? (
          <div className="card" style={{ marginTop: 20, padding: 20 }}>
            <p>
              Public registration is closed during Controlled Launch. Use an invite link from RTAS, or{" "}
              <Link href="/login">sign in</Link> if you already have access.
            </p>
            <p className="meta">Email verification and license purchase continue inside the Customer Portal after invite acceptance.</p>
          </div>
        ) : (
          <form className="card" style={{ marginTop: 20, padding: 20, display: "grid", gap: 12 }} action="/login">
            <input type="hidden" name="invite" value={invite} />
            <label>
              Work email
              <input name="email" type="email" required style={{ display: "block", width: "100%", marginTop: 4 }} />
            </label>
            <p className="meta">
              After sign-in, complete email verification (when enabled), purchase a plan, activate your license, then
              download the installer.
            </p>
            <button type="submit" className="btn btn-primary">
              Continue to sign in
            </button>
          </form>
        )}
      </main>
      <SiteFooter />
    </div>
  );
}
