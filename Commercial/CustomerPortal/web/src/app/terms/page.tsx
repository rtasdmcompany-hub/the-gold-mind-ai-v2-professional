import { LegalShell } from "@/components/enterprise/LegalShell";
import { brand } from "@/lib/brand";

export default function TermsPage() {
  return (
    <LegalShell title="Terms of Service">
      <p>
        <strong>Status:</strong> Production draft — OWNER REVIEW REQUIRED before open commercial launch.
        Effective date (draft): 31 July 2026. These Terms govern access to {brand.productName} website,
        Customer Portal, downloads, and related commercial services operated by {brand.companyName}.
      </p>

      <h2>1. Agreement</h2>
      <p>
        By creating an account, purchasing a license, or downloading the installer, you agree to these Terms, the
        EULA, Privacy Policy, Refund Policy, Cookie Policy, Disclaimer, and Risk Disclosure.
      </p>

      <h2>2. Accounts and Eligibility</h2>
      <p>
        You must provide accurate registration information and keep credentials confidential. You are responsible
        for activity under your account. We may suspend accounts for fraud, abuse, or terms violations.
      </p>

      <h2>3. Licenses and Acceptable Use</h2>
      <p>
        Licenses are personal/non-transferable per purchased seats. You may not reverse engineer the commercial
        portal, redistribute installer packages, share license keys, circumvent device limits, or use the service
        for unlawful purposes.
      </p>

      <h2>4. Payments</h2>
      <p>
        Fees are billed through our payment provider (Paddle). Taxes may apply. Access to commercial downloads and
        portal features depends on a valid license/subscription status.
      </p>

      <h2>5. Trading Risk</h2>
      <p>
        Automated trading involves substantial risk of loss. {brand.companyName} does not guarantee profits. See the Risk
        Disclosure. The Trading Engine runs under your control in MetaTrader 5.
      </p>

      <h2>6. Intellectual Property</h2>
      <p>
        Software, branding, documentation, and website content remain the property of {brand.companyName} or its licensors. License
        grants a limited right to use, not ownership.
      </p>

      <h2>7. Limitation of Liability</h2>
      <p>
        To the maximum extent permitted by law, {brand.companyName} is not liable for trading losses, indirect or consequential
        damages, or service interruptions beyond fees paid for the affected subscription period.
      </p>

      <h2>8. Termination</h2>
      <p>
        We may terminate or suspend access for breach. You may cancel subscriptions per the Refund Policy and
        provider rules. Provisions that should survive termination continue to apply.
      </p>

      <h2>9. Contact</h2>
      <p>
        <a href={`mailto:${brand.emails.legal}`}>{brand.emails.legal}</a> ·{" "}
        <a href={`mailto:${brand.emails.support}`}>{brand.emails.support}</a>
      </p>
    </LegalShell>
  );
}
