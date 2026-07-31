import { LegalShell } from "@/components/enterprise/LegalShell";

export default function PrivacyPage() {
  return (
    <LegalShell title="Privacy Policy">
      <p>
        <strong>Status:</strong> Production draft — OWNER REVIEW REQUIRED before open commercial launch.
        Effective date (draft): 31 July 2026. Publisher: RTAS Group of Companies (“RTAS”, “we”, “us”).
      </p>

      <h2>1. Scope</h2>
      <p>
        This Privacy Policy describes how we process personal data when you visit the THE GOLD MIND PROFESSIONAL
        website, create a Customer Portal account, purchase or activate a license, download software, or contact
        support. The MetaTrader 5 Trading Engine that runs on your machine is separate from this commercial portal
        and does not send trade strategy source code to RTAS.
      </p>

      <h2>2. Data We Collect</h2>
      <ul>
        <li>Account identity: name, email address, authentication credentials or OAuth identifiers</li>
        <li>License and device metadata: license identifiers, masked keys, device names, device fingerprint hashes</li>
        <li>Billing references: plan, invoice/payment IDs, PSP customer references (card data is processed by Paddle — never stored by RTAS)</li>
        <li>Support content: tickets, messages, and related attachments you submit</li>
        <li>Technical logs: IP address, user agent, session timestamps, security audit events</li>
      </ul>

      <h2>3. Purposes and Legal Bases</h2>
      <p>
        We process data to provide the product (contract), secure accounts and licenses (legitimate interests /
        legal obligation), send transactional email (contract), improve service reliability (legitimate interests),
        and comply with accounting and fraud-prevention obligations.
      </p>

      <h2>4. Processors and International Transfers</h2>
      <p>
        Depending on configuration, processors may include hosting (e.g. Vercel), durable data stores (e.g. Upstash),
        email delivery (e.g. Resend), authentication providers (e.g. Google OAuth), and payment processors (e.g. Paddle).
        Transfers outside your country of residence occur under the safeguards those providers offer.
      </p>

      <h2>5. Retention</h2>
      <p>
        Account and license records are retained while your account is active and for a reasonable period afterward
        for audit, fraud prevention, and legal retention. Support tickets and billing references follow commercial
        record-keeping practice. You may request deletion subject to legal holds.
      </p>

      <h2>6. Your Rights</h2>
      <p>
        Depending on applicable law, you may request access, correction, deletion, restriction, portability, or
        objection. Contact <a href="mailto:privacy@rtas.group">privacy@rtas.group</a>.
      </p>

      <h2>7. Security</h2>
      <p>
        We use encrypted transport (HTTPS), hashed credentials, session controls, role-based admin access, and
        license/device binding controls. No method of transmission or storage is perfectly secure.
      </p>

      <h2>8. Contact</h2>
      <p>
        Privacy: <a href="mailto:privacy@rtas.group">privacy@rtas.group</a> · Legal:{" "}
        <a href="mailto:legal@rtas.group">legal@rtas.group</a>
      </p>
    </LegalShell>
  );
}
