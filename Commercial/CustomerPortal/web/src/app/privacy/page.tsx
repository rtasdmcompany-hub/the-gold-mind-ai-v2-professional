import { LegalShell } from "@/components/enterprise/LegalShell";
import { brand } from "@/lib/brand";

export default function PrivacyPage() {
  return (
    <LegalShell title="Privacy Policy">
      <p>
        <strong>Effective date:</strong> January 2025 · <strong>Last updated:</strong> January 2025 · Publisher:{" "}
        {brand.companyName} (&quot;{brand.brandName}&quot;, &quot;we&quot;, &quot;us&quot;).
      </p>

      <h2>1. Introduction</h2>
      <p>
        {brand.companyName} (&quot;we&quot;, &quot;us&quot;, or &quot;our&quot;) respects your privacy and is
        committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose,
        and safeguard your information when you visit the {brand.productName} website, create a Customer Portal
        account, purchase or activate a license, download software, or contact support.
      </p>
      <p>
        This policy complies with the General Data Protection Regulation (GDPR) for users in the European
        Economic Area (EEA), the California Consumer Privacy Act (CCPA), and other applicable data protection
        laws.
      </p>

      <h2>2. Scope</h2>
      <p>
        This Privacy Policy describes how we process personal data when you visit the {brand.productName}{" "}
        website, create a Customer Portal account, purchase or activate a license, download software, or contact
        support. The MetaTrader 5 Trading Engine that runs on your machine is separate from this commercial
        portal and does not send trade strategy source code to {brand.companyName}.
      </p>

      <h2>3. Data We Collect</h2>
      <p>We may collect the following types of information:</p>

      <h3>Personal Information:</h3>
      <ul>
        <li>Full name and email address (account registration)</li>
        <li>Billing information (processed securely via our payment provider — card data is processed by Paddle, never stored by {brand.companyName})</li>
        <li>Authentication credentials or OAuth identifiers</li>
        <li>Communication records (support tickets, emails, messages)</li>
      </ul>

      <h3>Technical Information:</h3>
      <ul>
        <li>License and device metadata: license identifiers, masked keys, device names, device fingerprint hashes</li>
        <li>IP address, user agent, session timestamps</li>
        <li>Security audit events and technical logs</li>
        <li>Software version and update history</li>
      </ul>

      <h3>We Do NOT Collect:</h3>
      <ul>
        <li>Broker passwords or trading credentials</li>
        <li>Real-time trade data or account balances</li>
        <li>Personal financial records</li>
        <li>Trade strategy source code from your MT5 installation</li>
      </ul>

      <h2>4. How We Use Your Information</h2>
      <p>We use collected information for:</p>
      <ul>
        <li>
          <strong>License management:</strong> Activation, device binding, and validation
        </li>
        <li>
          <strong>Payment processing:</strong> Subscription billing and transaction records
        </li>
        <li>
          <strong>Software delivery:</strong> Providing download access and updates
        </li>
        <li>
          <strong>Customer support:</strong> Responding to inquiries and technical issues
        </li>
        <li>
          <strong>Security:</strong> Fraud prevention and unauthorized access detection
        </li>
        <li>
          <strong>Legal compliance:</strong> Meeting regulatory and accounting obligations
        </li>
        <li>
          <strong>Service improvement:</strong> Analyzing usage patterns to enhance the product
        </li>
      </ul>

      <h2>5. Legal Bases for Processing (GDPR)</h2>
      <p>
        We process data to provide the product (contract), secure accounts and licenses (legitimate interests /
        legal obligation), send transactional email (contract), improve service reliability (legitimate
        interests), and comply with accounting and fraud-prevention obligations.
      </p>

      <h2>6. Data Sharing &amp; Third Parties</h2>
      <p>
        We do not sell your personal data. Depending on configuration, processors may include:
      </p>
      <ul>
        <li>
          <strong>Hosting providers:</strong> Encrypted hosting and storage (e.g., Vercel)
        </li>
        <li>
          <strong>Data stores:</strong> Durable data storage (e.g., Upstash)
        </li>
        <li>
          <strong>Email delivery:</strong> Transactional email services (e.g., Resend)
        </li>
        <li>
          <strong>Authentication:</strong> OAuth providers (e.g., Google OAuth)
        </li>
        <li>
          <strong>Payment processors:</strong> Secure payment handling (e.g., Paddle)
        </li>
        <li>
          <strong>Legal requirements:</strong> When required by law, court order, or regulation
        </li>
        <li>
          <strong>Business transfers:</strong> In connection with a merger, acquisition, or sale of assets
        </li>
      </ul>
      <p>
        Transfers outside your country of residence occur under the safeguards those providers offer.
      </p>

      <h2>7. Data Security</h2>
      <p>
        We implement industry-standard security measures including: encrypted transport (HTTPS/TLS), hashed
        credentials, session controls, role-based admin access, license/device binding controls, encrypted data
        at rest, access controls, regular security audits, and secure development practices. However, no method
        of transmission over the Internet or electronic storage is 100% secure, and we cannot guarantee absolute
        security.
      </p>

      <h2>8. Your Rights (GDPR/CCPA)</h2>
      <p>Depending on your jurisdiction, you may have the right to:</p>
      <ul>
        <li>
          <strong>Access:</strong> Request a copy of your personal data
        </li>
        <li>
          <strong>Rectification:</strong> Request correction of inaccurate data
        </li>
        <li>
          <strong>Erasure:</strong> Request deletion of your data (&quot;right to be forgotten&quot;)
        </li>
        <li>
          <strong>Portability:</strong> Request data in a machine-readable format
        </li>
        <li>
          <strong>Restriction:</strong> Request limitation of data processing
        </li>
        <li>
          <strong>Objection:</strong> Object to processing based on legitimate interests
        </li>
        <li>
          <strong>Withdraw consent:</strong> Withdraw consent at any time
        </li>
      </ul>
      <p>
        To exercise these rights, contact{" "}
        <a href={`mailto:${brand.emails.privacy}`}>{brand.emails.privacy}</a>. We will respond within 30 days.
      </p>

      <h2>9. Data Retention</h2>
      <p>
        Account and license records are retained while your account is active and for a reasonable period
        afterward for audit, fraud prevention, and legal retention. Support tickets and billing references
        follow commercial record-keeping practice. License and billing records are retained for the duration of
        your account plus 7 years for tax/legal compliance. You may request deletion at any time, subject to
        legal retention requirements.
      </p>

      <h2>10. Cookies</h2>
      <p>
        Our website uses essential cookies for authentication and session management. We do not use third-party
        advertising cookies or tracking pixels. You may disable cookies in your browser settings, though this
        may affect website functionality.
      </p>

      <h2>11. Children&apos;s Privacy</h2>
      <p>
        Our services are not directed to individuals under 18 years of age. We do not knowingly collect personal
        information from children. If you believe a child has provided us with personal data, please contact us
        immediately.
      </p>

      <h2>12. Changes to This Policy</h2>
      <p>
        We may update this Privacy Policy from time to time. Changes will be posted on this page with an updated
        effective date. Material changes will be communicated via email or portal notification. Continued use of
        our services after changes constitutes acceptance of the updated policy.
      </p>

      <h2>13. Contact Us</h2>
      <p>
        For privacy-related inquiries, data requests, or concerns:
      </p>
      <ul>
        <li>
          Privacy: <a href={`mailto:${brand.emails.privacy}`}>{brand.emails.privacy}</a>
        </li>
        <li>
          Legal: <a href={`mailto:${brand.emails.legal}`}>{brand.emails.legal}</a>
        </li>
        <li>
          Support: <a href={`mailto:${brand.emails.support}`}>{brand.emails.support}</a>
        </li>
      </ul>
      <p>
        Subject line: &quot;Privacy Request&quot; — We will respond within 30 days.
      </p>
    </LegalShell>
  );
}
