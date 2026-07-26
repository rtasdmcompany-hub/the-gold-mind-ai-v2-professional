import { auth, signIn } from "@/auth";
import { redirect } from "next/navigation";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ callbackUrl?: string }>;
}) {
  const session = await auth();
  if (session?.user) redirect("/portal");

  const sp = await searchParams;
  const callbackUrl = sp.callbackUrl || "/portal";
  const googleEnabled = !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);

  return (
    <div className="login-page">
      <div className="login-card">
        <p className="brand-mark">RTAS GROUP OF COMPANIES</p>
        <h1>THE GOLD MIND</h1>
        <p>Sign in to your Professional Customer Portal. This service is separate from the Trading Engine.</p>

        <div className="stack">
          {googleEnabled && (
            <form
              action={async () => {
                "use server";
                await signIn("google", { redirectTo: callbackUrl });
              }}
            >
              <button type="submit" className="btn btn-primary" style={{ width: "100%" }}>
                Continue with Google
              </button>
            </form>
          )}

          <form
            action={async (fd) => {
              "use server";
              const email = String(fd.get("email") || "demo@goldmind.local");
              await signIn("demo", { email, redirectTo: callbackUrl });
            }}
            className="stack"
          >
            <div className="field">
              <label htmlFor="email">Demo email (MVP / local)</label>
              <input id="email" name="email" type="email" defaultValue="demo@goldmind.local" />
            </div>
            <button type="submit" className="btn btn-primary" style={{ width: "100%" }}>
              Demo Sign-In
            </button>
          </form>
        </div>

        <p className="note">
          Demo: <code>demo@goldmind.local</code> (customer) · <code>admin@goldmind.local</code> (admin console).
          {googleEnabled
            ? " Google OAuth is configured."
            : " Set GOOGLE_CLIENT_ID / SECRET to enable Google OAuth."}
        </p>
      </div>
    </div>
  );
}
