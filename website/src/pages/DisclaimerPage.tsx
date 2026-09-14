import { Shield } from 'lucide-react';

export default function DisclaimerPage() {
  return (
    <main className="pt-24 pb-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <Shield className="w-12 h-12 text-amber-400 mx-auto mb-4" />
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            General <span className="text-amber-400">Disclaimer</span>
          </h1>
          <p className="text-sm text-gray-500">
            Effective date: January 2025 · Last updated: January 2025
          </p>
        </div>

        <div className="space-y-8">
          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">1. General Disclaimer</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              The information provided on this website and through THE GOLD MIND AI v2.0 PROFESSIONAL software is for general informational purposes only. While we strive to keep the information up to date and accurate, we make no representations or warranties of any kind, express or implied, about the completeness, accuracy, reliability, suitability, or availability of the information, products, services, or related graphics contained on the website.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">2. No Guarantee of Profits</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              THE GOLD MIND AI v2.0 PROFESSIONAL does not guarantee any specific results or profits. Trading in financial markets carries a high level of risk. Any reliance you place on information provided is strictly at your own risk. In no event will we be liable for any loss or damage including without limitation, indirect or consequential loss or damage, or any loss or damage whatsoever arising from loss of data or profits arising out of, or in connection with, the use of this software.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">3. Third-Party Links</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              This website may contain links to external sites (such as MQL5 Market, broker websites, VPS providers). These links are provided for convenience and informational purposes only. We do not endorse, control, or assume responsibility for the content, privacy policies, or practices of any third-party websites.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">4. Software Limitations</h2>
            <p className="text-sm text-gray-300 leading-relaxed mb-3">
              THE GOLD MIND AI v2.0 PROFESSIONAL is a tool designed to assist with trade execution on MetaTrader 5. It has inherent limitations including but not limited to:
            </p>
            <ul className="text-sm text-gray-300 space-y-2 ml-4">
              <li>• Cannot predict future market movements with certainty</li>
              <li>• Performance varies based on market conditions</li>
              <li>• Dependent on broker execution quality and infrastructure</li>
              <li>• May experience periods of drawdown or non-performance</li>
              <li>• Not suitable for all market conditions or instruments</li>
            </ul>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">5. Intellectual Property</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              All content, software, algorithms, branding, and materials on this website and within THE GOLD MIND software are the intellectual property of THE GOLD MIND and are protected by applicable copyright, trademark, and other intellectual property laws. Unauthorized reproduction, distribution, reverse engineering, or modification is strictly prohibited and may result in license termination and legal action.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">6. Fraud Warning</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              Be cautious of unauthorized websites, social media pages, or messaging groups (Telegram, WhatsApp, etc.) claiming to sell, rent, or "guarantee profits" with THE GOLD MIND AI v2.0 PROFESSIONAL or any imitation. THE GOLD MIND is available only through the official website and the MQL5 Market. Never share license keys, portal passwords, or broker credentials with anyone.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-amber-500/20 bg-amber-500/5">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">7. Limitation of Liability</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              To the maximum extent permitted by applicable law, THE GOLD MIND, its developers, affiliates, partners, and employees shall not be liable for any direct, indirect, incidental, special, consequential, or exemplary damages, including but not limited to damages for loss of profits, goodwill, data, or other intangible losses, resulting from: (i) the use or inability to use the software; (ii) any trading losses incurred; (iii) unauthorized access to or alteration of your data; (iv) any other matter relating to the software or website.
            </p>
          </section>

          <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <h2 className="text-xl font-semibold text-amber-400 mb-3">8. Contact</h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              If you have questions about this disclaimer, please contact us at{' '}
              <a href="mailto:support@thegoldmind.ai" className="text-amber-400 hover:text-amber-300">
                support@thegoldmind.ai
              </a>
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
