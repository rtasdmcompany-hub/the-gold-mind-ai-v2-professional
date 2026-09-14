import { useState } from 'react';
import { BookOpen, ChevronDown, ChevronUp, Download, Shield, Settings, HelpCircle, BarChart3 } from 'lucide-react';

export default function DocsPage() {
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const faqs = [
    {
      q: 'How do I activate my license?',
      a: 'Sign in to the Customer Portal, navigate to Licenses, and enter your license key. Device binding occurs automatically on first MT5 connection. Ensure you are running the latest MT5 build.',
    },
    {
      q: 'Where do I download the installer?',
      a: 'Authenticated customers can download checksum-verified installers from Portal → Downloads. Each package includes SHA-256 checksums and release notes. Always verify the checksum before installation.',
    },
    {
      q: 'Is the Trading Engine modified by the portal?',
      a: 'No. The verified Core Expert Advisor operates exclusively on MetaTrader 5. The portal handles licensing, billing, and updates only. The EA file is never altered by the web infrastructure.',
    },
    {
      q: 'What payment methods are supported?',
      a: 'We support major credit/debit cards (Visa, Mastercard, Amex) and select digital payment methods through our secure payment provider (Paddle). All transactions are encrypted.',
    },
    {
      q: 'Can I use this on multiple devices?',
      a: 'Each license is bound to one device at a time. If you need to switch devices, contact support to deactivate the current binding. Enterprise multi-device licenses are available on request.',
    },
    {
      q: 'What brokers are compatible?',
      a: 'THE GOLD MIND works with any MT5-compatible broker. We recommend ECN/Raw spread accounts for optimal execution. Ensure XAUUSD is available on your broker platform.',
    },
    {
      q: 'How do I update the software?',
      a: 'Updates are distributed through the Customer Portal → Downloads section. Each update includes release notes and a new SHA-256 checksum. Yearly and Lifetime plans include all future updates.',
    },
    {
      q: 'What is the minimum account size?',
      a: 'We recommend a minimum of $500 for standard lot sizing. For micro-lot accounts, $200 minimum. The EA includes dynamic position sizing based on account equity.',
    },
  ];

  return (
    <main className="pt-24 pb-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            <span className="text-amber-400">Documentation</span>
          </h1>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Guides, FAQ, and resources for THE GOLD MIND AI v2.0 PROFESSIONAL.
          </p>
        </div>

        {/* Quick Links */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
          <div className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14] hover:border-amber-500/30 transition-all">
            <BookOpen className="w-8 h-8 text-amber-400 mb-4" />
            <h3 className="text-lg font-semibold text-white mb-2">Getting Started</h3>
            <p className="text-sm text-gray-400 mb-4">
              Installation guide, first activation, and initial configuration steps.
            </p>
            <ol className="text-sm text-gray-300 space-y-2">
              <li>1. Download installer from Portal</li>
              <li>2. Verify SHA-256 checksum</li>
              <li>3. Copy .ex5 file to MT5 Experts folder</li>
              <li>4. Activate license in Portal</li>
              <li>5. Attach EA to XAUUSD chart</li>
            </ol>
          </div>

          <div className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14] hover:border-amber-500/30 transition-all">
            <Settings className="w-8 h-8 text-amber-400 mb-4" />
            <h3 className="text-lg font-semibold text-white mb-2">Configuration</h3>
            <p className="text-sm text-gray-400 mb-4">
              Key parameters and recommended settings for optimal performance.
            </p>
            <ul className="text-sm text-gray-300 space-y-2">
              <li>• Risk per trade: 0.5% - 2%</li>
              <li>• Max open trades: 3-5</li>
              <li>• Magic Number: unique per account</li>
              <li>• Slippage tolerance: 30 points</li>
              <li>• News filter: enabled (recommended)</li>
            </ul>
          </div>

          <div className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14] hover:border-amber-500/30 transition-all">
            <Shield className="w-8 h-8 text-amber-400 mb-4" />
            <h3 className="text-lg font-semibold text-white mb-2">Security</h3>
            <p className="text-sm text-gray-400 mb-4">
              License protection, device binding, and verification procedures.
            </p>
            <ul className="text-sm text-gray-300 space-y-2">
              <li>• SHA-256 checksum verification</li>
              <li>• Device-bound license keys</li>
              <li>• Online validation on activation</li>
              <li>• Encrypted license storage</li>
              <li>• Audit trail logging</li>
            </ul>
          </div>
        </div>

        {/* FAQ Section */}
        <div className="max-w-3xl mx-auto">
          <h2 className="text-2xl font-bold text-center mb-8 flex items-center justify-center gap-2">
            <HelpCircle className="w-6 h-6 text-amber-400" />
            Frequently Asked Questions
          </h2>

          <div className="space-y-3">
            {faqs.map((faq, i) => (
              <div
                key={i}
                className="rounded-xl border border-gray-800 bg-[#0d0d14] overflow-hidden"
              >
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  className="w-full flex items-center justify-between p-5 text-left hover:bg-white/[0.02] transition-colors"
                >
                  <span className="text-sm font-medium text-white pr-4">{faq.q}</span>
                  {openFaq === i ? (
                    <ChevronUp className="w-5 h-5 text-amber-400 flex-shrink-0" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-gray-500 flex-shrink-0" />
                  )}
                </button>
                {openFaq === i && (
                  <div className="px-5 pb-5">
                    <p className="text-sm text-gray-400 leading-relaxed">{faq.a}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* EA Installation Guide */}
        <div className="max-w-3xl mx-auto mt-16">
          <h2 className="text-2xl font-bold text-center mb-8">
            EA <span className="text-amber-400">Installation Guide</span>
          </h2>
          
          <div className="p-8 rounded-xl border border-gray-800 bg-[#0d0d14]">
            <ol className="space-y-6">
              <li className="flex gap-4">
                <span className="flex-shrink-0 w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold text-sm">1</span>
                <div>
                  <h4 className="text-white font-semibold mb-1">Download the EA File</h4>
                  <p className="text-sm text-gray-400">
                    Sign in to Customer Portal → Downloads → Download THE GOLD MIND .ex5 file
                  </p>
                </div>
              </li>
              <li className="flex gap-4">
                <span className="flex-shrink-0 w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold text-sm">2</span>
                <div>
                  <h4 className="text-white font-semibold mb-1">Verify Checksum</h4>
                  <p className="text-sm text-gray-400">
                    Compare SHA-256 checksum provided in Portal with your downloaded file to ensure integrity
                  </p>
                </div>
              </li>
              <li className="flex gap-4">
                <span className="flex-shrink-0 w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold text-sm">3</span>
                <div>
                  <h4 className="text-white font-semibold mb-1">Copy to MT5 Experts Folder</h4>
                  <p className="text-sm text-gray-400">
                    Open MT5 → File → Open Data Folder → MQL5 → Experts → Paste the .ex5 file here
                  </p>
                </div>
              </li>
              <li className="flex gap-4">
                <span className="flex-shrink-0 w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold text-sm">4</span>
                <div>
                  <h4 className="text-white font-semibold mb-1">Activate License</h4>
                  <p className="text-sm text-gray-400">
                    Customer Portal → Licenses → Enter your license key → Device binding occurs automatically
                  </p>
                </div>
              </li>
              <li className="flex gap-4">
                <span className="flex-shrink-0 w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold text-sm">5</span>
                <div>
                  <h4 className="text-white font-semibold mb-1">Attach to Chart</h4>
                  <p className="text-sm text-gray-400">
                    In MT5 Navigator → Expert Advisors → Drag THE GOLD MIND onto XAUUSD chart → Configure settings → Enable AutoTrading
                  </p>
                </div>
              </li>
              <li className="flex gap-4">
                <span className="flex-shrink-0 w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold text-sm">6</span>
                <div>
                  <h4 className="text-white font-semibold mb-1">Monitor & Manage</h4>
                  <p className="text-sm text-gray-400">
                    Ensure AutoTrading button is enabled (green). Monitor via Journal/Experts tabs. Use VPS for 24/7 operation.
                  </p>
                </div>
              </li>
            </ol>
          </div>
        </div>

        {/* Verified Track Record Links */}
        <div className="max-w-3xl mx-auto mt-16 p-8 rounded-xl bg-gradient-to-b from-amber-500/10 to-transparent border border-amber-500/20 text-center">
          <BarChart3 className="w-10 h-10 text-amber-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-white mb-2">Verified Live Performance</h3>
          <p className="text-sm text-gray-400 mb-6">
            View our independently verified trading results on Myfxbook and MQL5 Market.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="https://www.myfxbook.com/portfolio/gold-mind-ai/12200748"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-6 py-3 bg-amber-500 hover:bg-amber-400 text-black font-semibold rounded-lg transition-all"
            >
              <BarChart3 className="w-4 h-4" />
              View Myfxbook Track Record
            </a>
            <a
              href="https://www.mql5.com/en/market/product/183685"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 px-6 py-3 border border-amber-500/30 hover:border-amber-500/60 text-amber-400 font-semibold rounded-lg transition-all"
            >
              <Download className="w-4 h-4" />
              Visit MQL5 Market
            </a>
          </div>
        </div>
      </div>
    </main>
  );
}
