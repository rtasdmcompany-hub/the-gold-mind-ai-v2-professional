import { LegalShell } from "@/components/enterprise/LegalShell";
import { brand } from "@/lib/brand";

export default function TermsPage() {
  return (
    <LegalShell title="Terms of Service">
      <p>
        <strong>Effective date:</strong> January 2025 · <strong>Last updated:</strong> January 2025. These
        Terms govern access to the {brand.productName} website, Customer Portal, downloads, and related
        commercial services operated by {brand.companyName}.
      </p>

      <h2>1. Acceptance of Terms</h2>
      <p>
        By creating an account, purchasing a license, or downloading the installer, you agree to these Terms,
        the EULA, Privacy Policy, Refund Policy, Cookie Policy, Disclaimer, and Risk Disclosure. If you do not
        agree to these Terms, do not use our Services. These Terms constitute a legally binding agreement
        between you (&quot;User,&quot; &quot;Customer,&quot; or &quot;Licensee&quot;) and {brand.companyName}{" "}
        (&quot;Company,&quot; &quot;we,&quot; or &quot;us&quot;).
      </p>

      <h2>2. Accounts and Eligibility</h2>
      <p>
        You must provide accurate registration information and keep credentials confidential. You are
        responsible for all activity under your account. You must be at least 18 years of age to use our
        Services. We may suspend accounts for fraud, abuse, or terms violations.
      </p>

      <h2>3. License Grant</h2>
      <p>
        Subject to these Terms and payment of applicable fees, we grant you a limited, non-exclusive,
        non-transferable, revocable license to:
      </p>
      <ul>
        <li>Use {brand.productFullName} Expert Advisor on MetaTrader 5</li>
        <li>Access the Customer Portal for license management</li>
        <li>Download verified software updates during your license period</li>
        <li>Access documentation and support resources</li>
      </ul>
      <p>
        This license is personal to you and may not be sublicensed, transferred, or shared.
      </p>

      <h2>4. License Restrictions</h2>
      <p>You agree NOT to:</p>
      <ul>
        <li>Reverse engineer, decompile, or disassemble the software</li>
        <li>Share, resell, or distribute license keys or software files</li>
        <li>Use the software on more devices than permitted by your license</li>
        <li>Remove or alter any copyright, trademark, or proprietary notices</li>
        <li>Use the software for illegal activities or in restricted jurisdictions</li>
        <li>Create derivative works based on the software</li>
        <li>Attempt to bypass license validation or device binding</li>
        <li>Publish or share proprietary algorithm details</li>
      </ul>

      <h2>5. Payments and Subscriptions</h2>
      <p>
        All fees are quoted in USD unless otherwise stated. Payment is processed securely through our payment
        provider (Paddle). Taxes may apply based on your jurisdiction.
      </p>
      <ul>
        <li>
          <strong>Trial:</strong> Free 14-day evaluation period
        </li>
        <li>
          <strong>Monthly:</strong> Auto-renews monthly; cancel anytime
        </li>
        <li>
          <strong>Yearly:</strong> Annual billing with savings
        </li>
        <li>
          <strong>Lifetime:</strong> One-time payment, includes all future updates
        </li>
      </ul>
      <p>
        Prices are subject to change with 30 days notice for existing subscribers. Access to commercial
        downloads and portal features depends on a valid license/subscription status.
      </p>

      <h2>6. Refund Policy</h2>
      <p>
        Due to the digital nature of the software, all sales are final once the license key has been activated
        and delivered. A 14-day free trial is available for evaluation before purchase. If you experience
        technical issues preventing activation or operation, contact support within 7 days of purchase for
        assistance. Refund requests for activated licenses will be evaluated on a case-by-case basis.
      </p>

      <h2>7. Trading Risk</h2>
      <p>
        Automated trading involves substantial risk of loss. {brand.companyName} does not guarantee profits.
        See the Risk Disclosure for comprehensive risk information. The Trading Engine runs under your control
        in MetaTrader 5. You are solely responsible for all trading decisions and outcomes.
      </p>

      <h2>8. Intellectual Property</h2>
      <p>
        All software, code, algorithms, designs, branding, logos, documentation, and content are the exclusive
        property of {brand.companyName} and are protected by copyright, trademark, and other intellectual
        property laws. Your license does not grant ownership of any intellectual property. All rights not
        expressly granted are reserved.
      </p>

      <h2>9. Disclaimer of Warranties</h2>
      <p>
        THE SOFTWARE IS PROVIDED &quot;AS IS&quot; WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED,
        INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
        NON-INFRINGEMENT. WE DO NOT WARRANT THAT THE SOFTWARE WILL BE ERROR-FREE, UNINTERRUPTED, OR THAT IT
        WILL GENERATE PROFITS. TRADING INVOLVES SUBSTANTIAL RISK OF LOSS.
      </p>

      <h2>10. Limitation of Liability</h2>
      <p>
        TO THE MAXIMUM EXTENT PERMITTED BY LAW, {brand.companyName} SHALL NOT BE LIABLE FOR ANY INDIRECT,
        INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS,
        DATA, TRADING LOSSES, OR BUSINESS INTERRUPTION, ARISING OUT OF OR RELATED TO YOUR USE OF THE SERVICES,
        REGARDLESS OF THE THEORY OF LIABILITY. Our total liability shall not exceed the fees paid for the
        affected subscription period.
      </p>

      <h2>11. Termination</h2>
      <p>We may terminate or suspend your license immediately if you:</p>
      <ul>
        <li>Violate these Terms of Service</li>
        <li>Engage in fraudulent activity</li>
        <li>Share or redistribute the software</li>
        <li>Attempt to reverse engineer the software</li>
        <li>Fail to pay subscription fees</li>
      </ul>
      <p>
        Upon termination, your right to use the software ceases immediately. Lifetime licenses remain valid
        unless terminated for cause. You may cancel subscriptions per the Refund Policy and provider rules.
        Provisions that should survive termination continue to apply.
      </p>

      <h2>12. Governing Law</h2>
      <p>
        These Terms shall be governed by and construed in accordance with international commercial law
        principles. Any disputes arising from these Terms shall be resolved through binding arbitration. You
        agree that any legal proceedings must be initiated within one year of the cause of action.
      </p>

      <h2>13. Modifications</h2>
      <p>
        We reserve the right to modify these Terms at any time. Changes will be effective upon posting to this
        page. Material changes will be communicated via email or portal notification at least 30 days before
        taking effect. Continued use of the Services after changes constitutes acceptance.
      </p>

      <h2>14. Severability</h2>
      <p>
        If any provision of these Terms is found to be unenforceable or invalid, that provision shall be
        limited or eliminated to the minimum extent necessary so that these Terms shall otherwise remain in
        full force and effect and enforceable.
      </p>

      <h2>15. Contact</h2>
      <p>For questions about these Terms:</p>
      <ul>
        <li>
          Legal: <a href={`mailto:${brand.emails.legal}`}>{brand.emails.legal}</a>
        </li>
        <li>
          Support: <a href={`mailto:${brand.emails.support}`}>{brand.emails.support}</a>
        </li>
      </ul>
    </LegalShell>
  );
}
