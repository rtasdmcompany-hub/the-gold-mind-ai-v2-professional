import { LegalShell } from "@/components/enterprise/LegalShell";
import { brand } from "@/lib/brand";

export default function DisclaimerPage() {
  return (
    <LegalShell title="Disclaimer">
      <p>
        <strong>Status:</strong> Production draft — OWNER REVIEW REQUIRED before open commercial launch.
        Effective date (draft): 31 July 2026.
      </p>

      <h2>1. No Investment Advice</h2>
      <p>
        {brand.productName} and related materials are software tools. They are not investment advice,
        brokerage services, portfolio management, or a solicitation to buy or sell any financial instrument.
      </p>

      <h2>2. No Performance Guarantee</h2>
      <p>
        Past simulated or live results do not guarantee future performance. Market conditions change. You may lose
        some or all of your capital.
      </p>

      <h2>3. Independent Operation</h2>
      <p>
        The MetaTrader 5 Trading Engine executes under your broker account and settings. {brand.companyName} does not operate your
        trading account, place discretionary human trades on your behalf, or control your broker relationship.
      </p>

      <h2>4. Third-Party Services</h2>
      <p>
        Hosting, payment, email, and OAuth providers are third parties with their own terms. Outages or policy
        changes at those providers may affect portal availability without affecting your local EA installation.
      </p>

      <h2>5. Contact</h2>
      <p>
        <a href={`mailto:${brand.emails.legal}`}>{brand.emails.legal}</a> ·{" "}
        <a href={`mailto:${brand.emails.support}`}>{brand.emails.support}</a>
      </p>
    </LegalShell>
  );
}
