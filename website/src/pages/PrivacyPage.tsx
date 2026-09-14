import { Lock } from 'lucide-react';

export default function PrivacyPage() {
  return (
    <main className="pt-24 pb-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <Lock className="w-12 h-12 text-amber-400 mx-auto mb-4" />
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            Privacy <span className="text-amber-400">Policy</span>
          </h1>
          <p className="text-sm text-gray-500">
            Effective date: January 2025 · Last updated: January 2025
          </p>
        </div>

        <div className="space-y-8">
          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">1. Introduction</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              THE GOLD MIND ("we," "us," or "our") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website, use our Customer Portal, or purchase our software products.
            </p>
            <p className="text-sm text-gray-300 leading-relaxed mt-2">
              This policy complies with the General Data Protection Regulation (GDPR) for users in the European Economic Area (EEA), the California Consumer Privacy Act (CCPA), and other applicable data protection laws.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">2. Information We Collect</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">We may collect the following types of information:</p>
            
            <h3 className="text-sm font-semibold text-white mt-4 mb-2">Personal Information:</h3>
            <ul className="text-sm text-gray-300 space-y-1 ml-4">
              <li>• Full name and email address (account registration)</li>
              <li>• Billing information (processed securely via our payment provider)</li>
              <li>• Device identifiers (for license binding)</li>
              <li>• IP address and browser information</li>
              <li>• Communication records (support tickets, emails)</li>
            </ul>

            <h3 className="text-sm font-semibold text-white mt-4 mb-2">Technical Information:</h3>
            <ul className="text-sm text-gray-300 space-y-1 ml-4">
              <li>• MT5 account number (for license validation only)</li>
              <li>• Device hardware fingerprint (for license binding)</li>
              <li>• Software version and update history</li>
              <li>• Usage logs for support and troubleshooting</li>
            </ul>

            <h3 className="text-sm font-semibold text-white mt-4 mb-2">We Do NOT Collect:</h3>
            <ul className="text-sm text-gray-300 space-y-1 ml-4">
              <li>• Broker passwords or trading credentials</li>
              <li>• Real-time trade data or account balances</li>
              <li>• Personal financial records</li>
            </ul>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">3. How We Use Your Information</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">We use collected information for:</p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• <strong>License management:</strong> Activation, device binding, and validation</li>
              <li>• <strong>Payment processing:</strong> Subscription billing and transaction records</li>
              <li>• <strong>Software delivery:</strong> Providing download access and updates</li>
              <li>• <strong>Customer support:</strong> Responding to inquiries and technical issues</li>
              <li>• <strong>Security:</strong> Fraud prevention and unauthorized access detection</li>
              <li>• <strong>Legal compliance:</strong> Meeting regulatory obligations</li>
              <li>• <strong>Service improvement:</strong> Analyzing usage patterns to enhance the product</li>
            </ul>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">4. Data Sharing & Third Parties</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">
              We do not sell your personal data. We may share information with:
            </p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• <strong>Payment processors:</strong> For secure transaction handling (Paddle)</li>
              <li>• <strong>Cloud infrastructure:</strong> Encrypted hosting and storage providers</li>
              <li>• <strong>Legal requirements:</strong> When required by law, court order, or regulation</li>
              <li>• <strong>Business transfers:</strong> In connection with a merger, acquisition, or sale of assets</li>
            </ul>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">5. Data Security</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              We implement industry-standard security measures including: encryption in transit (TLS 1.3), encrypted data at rest, access controls, regular security audits, and secure development practices. However, no method of transmission over the Internet or electronic storage is 100% secure, and we cannot guarantee absolute security.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">6. Your Rights (GDPR/CCPA)</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">Depending on your jurisdiction, you may have the right to:</p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• <strong>Access:</strong> Request a copy of your personal data</li>
              <li>• <strong>Rectification:</strong> Request correction of inaccurate data</li>
              <li>• <strong>Erasure:</strong> Request deletion of your data ("right to be forgotten")</li>
              <li>• <strong>Portability:</strong> Request data in a machine-readable format</li>
              <li>• <strong>Restriction:</strong> Request limitation of data processing</li>
              <li>• <strong>Objection:</strong> Object to processing based on legitimate interests</li>
              <li>• <strong>Withdraw consent:</strong> Withdraw consent at any time</li>
            </ul>
            <p className="text-sm text-gray-300 leading-relaxed mt-3">
              To exercise these rights, contact us at{' '}
              <a href="mailto:support@thegoldmind.ai" className="text-amber-400 hover:text-amber-300">
                support@thegoldmind.ai
              </a>
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">7. Data Retention</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              We retain personal data only as long as necessary to fulfill the purposes outlined in this policy, comply with legal obligations, resolve disputes, and enforce agreements. License and billing records are retained for the duration of your account plus 7 years for tax/legal compliance. You may request deletion at any time, subject to legal retention requirements.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">8. Cookies</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              Our website uses essential cookies for authentication and session management. We do not use third-party advertising cookies or tracking pixels. You may disable cookies in your browser settings, though this may affect website functionality.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">9. Children's Privacy</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              Our services are not directed to individuals under 18 years of age. We do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us immediately.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">10. Changes to This Policy</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              We may update this Privacy Policy from time to time. Changes will be posted on this page with an updated effective date. Material changes will be communicated via email or portal notification. Continued use of our services after changes constitutes acceptance of the updated policy.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-amber-500/20 bg-amber-500/5">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">11. Contact Us</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              For privacy-related inquiries, data requests, or concerns:<br />
              Email: <a href="mailto:support@thegoldmind.ai" className="text-amber-400 hover:text-amber-300">support@thegoldmind.ai</a><br />
              Subject line: "Privacy Request"<br />
              We will respond within 30 days.
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
