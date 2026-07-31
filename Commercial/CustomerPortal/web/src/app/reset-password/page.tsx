import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { resetPasswordWithToken } from "@/server/accounts/service";
import { brand } from "@/lib/brand";

export const metadata: Metadata = {
  title: `Reset Password — ${brand.productName}`,
};

export default async function ResetPasswordPage({
  searchParams,
}: {
  searchParams: Promise<{ token?: string; email?: string; error?: string; done?: string }>;
}) {
  const sp = await searchParams;
  const token = (sp.token || "").trim();
  const email = (sp.email || "").trim();
  const linkValid = !!(token && email);

  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">Account Recovery</p>
          <h1 className="e-section-title">Reset Password</h1>
          <p className="e-section-sub">Choose a new password for your Customer Portal account.</p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 520 }}>
          <ScrollReveal>
            {sp.done === "1" ? (
              <div className="e-glass-card">
                <h2 style={{ marginTop: 0 }}>Password updated</h2>
                <p>Your password has been reset. You can sign in with your new password now.</p>
                <div className="e-btn-group" style={{ marginTop: 20 }}>
                  <Link href="/login" className="e-btn e-btn-primary">
                    Sign In
                  </Link>
                </div>
              </div>
            ) : !linkValid ? (
              <div className="e-glass-card">
                <p>
                  This reset link is missing required information. Request a new one from{" "}
                  <Link href="/forgot-password">Forgot password</Link>.
                </p>
              </div>
            ) : (
              <form
                className="e-glass-card e-form"
                action={async (fd) => {
                  "use server";
                  const newPassword = String(fd.get("newPassword") || "");
                  const confirmPassword = String(fd.get("confirmPassword") || "");
                  if (newPassword !== confirmPassword) {
                    redirect(
                      `/reset-password?token=${encodeURIComponent(token)}&email=${encodeURIComponent(email)}&error=${encodeURIComponent("Passwords do not match.")}`
                    );
                  }
                  const result = await resetPasswordWithToken({ email, token, newPassword });
                  if (!result.ok) {
                    redirect(
                      `/reset-password?token=${encodeURIComponent(token)}&email=${encodeURIComponent(email)}&error=${encodeURIComponent(result.error)}`
                    );
                  }
                  redirect("/reset-password?done=1");
                }}
              >
                {sp.error && (
                  <p className="e-login-error" role="alert">
                    {sp.error}
                  </p>
                )}
                <p style={{ fontSize: 13, color: "var(--e-text-muted)", marginTop: 0 }}>
                  Resetting password for <strong>{email}</strong>
                </p>
                <div className="e-field">
                  <label htmlFor="newPassword">New password</label>
                  <input
                    id="newPassword"
                    name="newPassword"
                    type="password"
                    required
                    minLength={8}
                    autoComplete="new-password"
                  />
                </div>
                <div className="e-field">
                  <label htmlFor="confirmPassword">Confirm new password</label>
                  <input
                    id="confirmPassword"
                    name="confirmPassword"
                    type="password"
                    required
                    minLength={8}
                    autoComplete="new-password"
                  />
                </div>
                <button type="submit" className="e-btn e-btn-primary">
                  Reset Password
                </button>
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  <Link href="/login">Back to sign in</Link>
                </p>
              </form>
            )}
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
