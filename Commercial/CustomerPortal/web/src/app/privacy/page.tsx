function LegalDraft({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <main style={{ maxWidth: 720, margin: "48px auto", padding: 24, fontFamily: "Georgia, serif" }}>
      <p style={{ letterSpacing: "0.08em", textTransform: "uppercase", fontSize: 12, opacity: 0.7 }}>
        THE GOLD MIND PROFESSIONAL
      </p>
      <h1 style={{ fontSize: 32, marginBottom: 8 }}>{title}</h1>
      <p style={{ color: "#666", marginBottom: 24 }}>
        Draft for Controlled Launch — counsel / Owner sign-off required before open Stable (BC-LEGAL).
      </p>
      <div style={{ lineHeight: 1.6 }}>{children}</div>
      <p style={{ marginTop: 32, fontSize: 13, color: "#666" }}>
        Core Trading Engine operation on MetaTrader is independent of this commercial website policy surface.
      </p>
    </main>
  );
}

export default function PrivacyPage() {
  return (
    <LegalDraft title="Privacy Policy">
      <p>
        RTAS processes account email, license metadata, device binding hashes, support tickets, and payment
        references via PSP processors (e.g. Paddle/PayPal). Card data is never stored on THE GOLD MIND portal.
      </p>
      <p>
        Contact: legal@rtas.local (placeholder). Full counsel-approved text will replace this draft before public
        Stable.
      </p>
    </LegalDraft>
  );
}
