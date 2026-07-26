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
    </main>
  );
}

export default function TermsPage() {
  return (
    <LegalDraft title="Terms of Service / EULA">
      <p>
        License grant is personal/non-transferable per purchased seat. Acceptable use excludes reverse engineering
        of the commercial portal and unauthorized redistribution of installer packages.
      </p>
      <p>Trading involves risk of loss. THE GOLD MIND does not guarantee profits.</p>
    </LegalDraft>
  );
}
