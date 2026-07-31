import { LegalShell } from "@/components/enterprise/LegalShell";

export default function CookiesPage() {
  return (
    <LegalShell title="Cookie Policy">
      <p>Session cookies are required for Customer Portal authentication and security.</p>
      <p>
        Analytics and marketing cookies are not enabled by default. Questions can be directed to{" "}
        <a href="mailto:privacy@rtas.group">privacy@rtas.group</a>.
      </p>
    </LegalShell>
  );
}
