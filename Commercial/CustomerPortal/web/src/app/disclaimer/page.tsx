import { LegalShell } from "@/components/enterprise/LegalShell";
import { brand } from "@/lib/brand";

export default function DisclaimerPage() {
  return (
    <LegalShell title="Disclaimer">
      <p>
        <strong>Effective date:</strong> January 2025 · <strong>Last updated:</strong> January 2025
      </p>

      <h2>1. General Disclaimer</h2>
      <p>
        The information provided on this website and through {brand.productFullName} software is for general
        informational purposes only. While we strive to keep the information up to date and accurate, we make
        no representations or warranties of any kind, express or implied, about the completeness, accuracy,
        reliability, suitability, or availability of the information, products, services, or related graphics
        contained on the website.
      </p>

      <h2>2. No Investment Advice</h2>
      <p>
        {brand.productFullName} and related materials are software tools. They are not investment advice,
        brokerage services, portfolio management, or a solicitation to buy or sell any financial instrument.
        {brand.productFullName} is commercial software, not financial, tax, legal, or investment advice.
        Consult qualified financial professionals before making any trading decisions.
      </p>

      <h2>3. No Performance Guarantee</h2>
      <p>
        {brand.productFullName} does not guarantee any specific results or profits. Trading in financial
        markets carries a high level of risk. Past simulated or live results do not guarantee future
        performance. Market conditions change. You may lose some or all of your capital. Any reliance you
        place on information provided is strictly at your own risk.
      </p>

      <h2>4. Independent Operation</h2>
      <p>
        The MetaTrader 5 Trading Engine executes under your broker account and settings. {brand.companyName}{" "}
        does not operate your trading account, place discretionary human trades on your behalf, or control
        your broker relationship. You are solely responsible for broker selection, account leverage, risk
        settings, and monitoring live trading activity.
      </p>

      <h2>5. Software Limitations</h2>
      <p>
        {brand.productFullName} is a tool designed to assist with trade execution on MetaTrader 5. It has
        inherent limitations including but not limited to:
      </p>
      <ul>
        <li>Cannot predict future market movements with certainty</li>
        <li>Performance varies based on market conditions</li>
        <li>Dependent on broker execution quality and infrastructure</li>
        <li>May experience periods of drawdown or non-performance</li>
        <li>Not suitable for all market conditions or instruments</li>
      </ul>

      <h2>6. Third-Party Services</h2>
      <p>
        This website may contain links to external sites (such as MQL5 Market, broker websites, VPS
        providers). These links are provided for convenience and informational purposes only. We do not
        endorse, control, or assume responsibility for the content, privacy policies, or practices of any
        third-party websites. Hosting, payment, email, and OAuth providers are third parties with their own
        terms. Outages or policy changes at those providers may affect portal availability without affecting
        your local EA installation.
      </p>

      <h2>7. Intellectual Property</h2>
      <p>
        All content, software, algorithms, branding, and materials on this website and within {brand.brandName}{" "}
        software are the intellectual property of {brand.companyName} and are protected by applicable copyright,
        trademark, and other intellectual property laws. Unauthorized reproduction, distribution, reverse
        engineering, or modification is strictly prohibited and may result in license termination and legal
        action.
      </p>

      <h2>8. Fraud Warning</h2>
      <p>
        Be cautious of unauthorized websites, social media pages, or messaging groups (Telegram, WhatsApp,
        etc.) claiming to sell, rent, or &quot;guarantee profits&quot; with {brand.productFullName} or any
        imitation. {brand.brandName} is available only through the official website and the MQL5 Market.
        Never share license keys, portal passwords, or broker credentials with anyone.
      </p>

      <h2>9. Limitation of Liability</h2>
      <p>
        To the maximum extent permitted by applicable law, {brand.brandName}, its developers, affiliates,
        partners, and employees shall not be liable for any direct, indirect, incidental, special,
        consequential, or exemplary damages, including but not limited to damages for loss of profits,
        goodwill, data, or other intangible losses, resulting from: (i) the use or inability to use the
        software; (ii) any trading losses incurred; (iii) unauthorized access to or alteration of your data;
        (iv) any other matter relating to the software or website.
      </p>

      <h2>10. Contact</h2>
      <p>
        If you have questions about this disclaimer, please contact us at{" "}
        <a href={`mailto:${brand.emails.support}`}>{brand.emails.support}</a> or{" "}
        <a href={`mailto:${brand.emails.legal}`}>{brand.emails.legal}</a>.
      </p>
    </LegalShell>
  );
}
