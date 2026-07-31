import { LegalShell } from "@/components/enterprise/LegalShell";

export default function RiskPage() {
  return (
    <LegalShell title="Risk Disclosure">
      <p>
        <strong>Status:</strong> Production draft — OWNER REVIEW REQUIRED before open commercial launch.
        Effective date (draft): 31 July 2026.
      </p>

      <h2>1. General Risk</h2>
      <p>
        Trading foreign exchange, metals, and CFDs involves substantial risk of loss and is not suitable for all
        investors. You can lose more than your initial deposit depending on account type and broker terms.
      </p>

      <h2>2. Automated Systems</h2>
      <p>
        Expert Advisors can experience drawdowns, slippage, requotes, connectivity failures, VPS outages, and
        broker-specific execution differences. AI monitoring modules do not eliminate market risk.
      </p>

      <h2>3. No Advice</h2>
      <p>
        THE GOLD MIND PROFESSIONAL is commercial software, not financial, tax, or investment advice. Consult
        qualified professionals before trading decisions.
      </p>

      <h2>4. Your Responsibility</h2>
      <p>
        You are solely responsible for broker selection, account leverage, risk settings, and monitoring live
        trading activity.
      </p>
    </LegalShell>
  );
}
