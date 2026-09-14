import { FileText } from 'lucide-react';

export default function TermsPage() {
  return (
    <main className="pt-24 pb-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <FileText className="w-12 h-12 text-amber-400 mx-auto mb-4" />
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            Terms of <span className="text-amber-400">Service</span>
          </h1>
          <p className="text-sm text-gray-500">
            Effective date: January 2025 · Last updated: January 2025
          </p>
        </div>

        <div className="space-y-8">
          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">1. Acceptance of Terms</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              By accessing or using THE GOLD MIND AI v2.0 PROFESSIONAL website, Customer Portal, or software products ("Services"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use our Services. These Terms constitute a legally binding agreement between you ("User," "Customer," or "Licensee") and THE GOLD MIND ("Company," "we," or "us").
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">2. License Grant</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">
              Subject to these Terms and payment of applicable fees, we grant you a limited, non-exclusive, non-transferable, revocable license to:
            </p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• Use THE GOLD MIND Expert Advisor on MetaTrader 5</li>
              <li>• Access the Customer Portal for license management</li>
              <li>• Download verified software updates during your license period</li>
              <li>• Access documentation and support resources</li>
            </ul>
            <p className="text-sm text-gray-300 leading-relaxed mt-3">
              This license is personal to you and may not be sublicensed, transferred, or shared.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">3. License Restrictions</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">You agree NOT to:</p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• Reverse engineer, decompile, or disassemble the software</li>
              <li>• Share, resell, or distribute license keys or software files</li>
              <li>• Use the software on more devices than permitted by your license</li>
              <li>• Remove or alter any copyright, trademark, or proprietary notices</li>
              <li>• Use the software for illegal activities or in restricted jurisdictions</li>
              <li>• Create derivative works based on the software</li>
              <li>• Attempt to bypass license validation or device binding</li>
              <li>• Publish or share proprietary algorithm details</li>
            </ul>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">4. Payment & Subscription</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">
              All fees are quoted in USD unless otherwise stated. Payment is processed securely through our payment provider (Paddle).
            </p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• <strong>Trial:</strong> Free 14-day evaluation period</li>
              <li>• <strong>Monthly:</strong> Auto-renews monthly; cancel anytime</li>
              <li>• <strong>Yearly:</strong> Annual billing with savings</li>
              <li>• <strong>Lifetime:</strong> One-time payment, includes all future updates</li>
            </ul>
            <p className="text-sm text-gray-300 leading-relaxed mt-3">
              Prices are subject to change with 30 days notice for existing subscribers.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">5. Refund Policy</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              Due to the digital nature of the software, all sales are final once the license key has been activated and delivered. A 14-day free trial is available for evaluation before purchase. If you experience technical issues preventing activation or operation, contact support within 7 days of purchase for assistance. Refund requests for activated licenses will be evaluated on a case-by-case basis.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">6. Intellectual Property</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              All software, code, algorithms, designs, branding, logos, documentation, and content are the exclusive property of THE GOLD MIND and are protected by copyright, trademark, and other intellectual property laws. Your license does not grant ownership of any intellectual property. All rights not expressly granted are reserved.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">7. Disclaimer of Warranties</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. WE DO NOT WARRANT THAT THE SOFTWARE WILL BE ERROR-FREE, UNINTERRUPTED, OR THAT IT WILL GENERATE PROFITS. TRADING INVOLVES SUBSTANTIAL RISK OF LOSS.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">8. Limitation of Liability</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE GOLD MIND SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, DATA, TRADING LOSSES, OR BUSINESS INTERRUPTION, ARISING OUT OF OR RELATED TO YOUR USE OF THE SERVICES, REGARDLESS OF THE THEORY OF LIABILITY.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">9. Termination</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">
              We may terminate or suspend your license immediately if you:
            </p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• Violate these Terms of Service</li>
              <li>• Engage in fraudulent activity</li>
              <li>• Share or redistribute the software</li>
              <li>• Attempt to reverse engineer the software</li>
              <li>• Fail to pay subscription fees</li>
            </ul>
            <p className="text-sm text-gray-300 leading-relaxed mt-3">
              Upon termination, your right to use the software ceases immediately. Lifetime licenses remain valid unless terminated for cause.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">10. Governing Law</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              These Terms shall be governed by and construed in accordance with international commercial law principles. Any disputes arising from these Terms shall be resolved through binding arbitration. You agree that any legal proceedings must be initiated within one year of the cause of action.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">11. Modifications</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              We reserve the right to modify these Terms at any time. Changes will be effective upon posting to this page. Material changes will be communicated via email or portal notification at least 30 days before taking effect. Continued use of the Services after changes constitutes acceptance.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">12. Severability</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary so that these Terms shall otherwise remain in full force and effect and enforceable.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-amber-500/20 bg-amber-500/5">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">13. Contact</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              For questions about these Terms:<br />
              Email: <a href="mailto:support@thegoldmind.ai" className="text-amber-400 hover:text-amber-300">support@thegoldmind.ai</a><br />
              Billing: <a href="mailto:billing@thegoldmind.ai" className="text-amber-400 hover:text-amber-300">billing@thegoldmind.ai</a>
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
