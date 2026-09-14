import { AlertTriangle } from 'lucide-react';

export default function RiskPage() {
  return (
    <main className="pt-24 pb-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <AlertTriangle className="w-12 h-12 text-amber-400 mx-auto mb-4" />
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            Risk <span className="text-amber-400">Disclosure</span>
          </h1>
          <p className="text-sm text-gray-500">
            Effective date: January 2025 · Last updated: January 2025
          </p>
        </div>

        <div className="prose prose-invert max-w-none">
          <div className="space-y-8">
            <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">1. General Risk Warning</h2>
              <p className="text-sm text-gray-300 leading-relaxed">
                Trading foreign exchange (Forex), metals (including gold/XAUUSD), cryptocurrencies, and Contracts for Difference (CFDs) involves substantial risk of loss and is not suitable for all investors. You can lose more than your initial deposit depending on your account type, broker terms, and leverage used. You should carefully consider whether trading is appropriate for you in light of your financial condition, experience, and risk tolerance.
              </p>
            </section>

            <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">2. Automated Trading Systems Risk</h2>
              <p className="text-sm text-gray-300 leading-relaxed mb-3">
                Expert Advisors (EAs) and automated trading systems can experience:
              </p>
              <ul className="text-sm text-gray-300 space-y-2 ml-4">
                <li>• <strong>Drawdowns:</strong> Periods of consecutive losses that may exceed expected parameters</li>
                <li>• <strong>Slippage:</strong> Execution prices may differ from expected prices, especially during high volatility</li>
                <li>• <strong>Requotes:</strong> Broker may reject orders at quoted prices</li>
                <li>• <strong>Connectivity failures:</strong> Internet outages, VPS failures, or broker server issues</li>
                <li>• <strong>Broker-specific execution differences:</strong> Spreads, commissions, and execution speeds vary</li>
                <li>• <strong>Platform crashes:</strong> MT5 may experience technical issues</li>
              </ul>
              <p className="text-sm text-gray-300 leading-relaxed mt-3">
                AI monitoring modules and signal intelligence do not eliminate market risk. No system can guarantee profits in all market conditions.
              </p>
            </section>

            <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">3. No Financial Advice</h2>
              <p className="text-sm text-gray-300 leading-relaxed">
                THE GOLD MIND AI v2.0 PROFESSIONAL is commercial software, not financial, tax, legal, or investment advice. The software does not constitute a recommendation to buy or sell any financial instrument. Past performance, backtested results, and displayed statistics do not guarantee future performance. Consult qualified financial professionals before making any trading decisions.
              </p>
            </section>

            <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">4. Your Responsibility</h2>
              <p className="text-sm text-gray-300 leading-relaxed mb-3">
                As a user, you are solely responsible for:
              </p>
              <ul className="text-sm text-gray-300 space-y-2 ml-4">
                <li>• Selection of broker and account type</li>
                <li>• Account leverage and margin settings</li>
                <li>• Risk parameters and position sizing</li>
                <li>• Monitoring live trading activity</li>
                <li>• Ensuring VPS/infrastructure reliability</li>
                <li>• Compliance with your local regulations</li>
                <li>• Tax reporting obligations</li>
              </ul>
            </section>

            <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">5. Performance Data Disclaimer</h2>
              <p className="text-sm text-gray-300 leading-relaxed">
                Any performance data, statistics, win rates, or return figures displayed on this website or within the software are for illustrative and informational purposes only. They may be based on historical backtesting, simulated environments, or specific market conditions that may not repeat. Real-world trading results will vary based on market conditions, broker execution, spread, slippage, and other factors.
              </p>
            </section>

            <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">6. AI & Algorithmic Trading Limitations</h2>
              <p className="text-sm text-gray-300 leading-relaxed">
                While AI monitoring modules and algorithmic logic can reduce emotional trading decisions and provide systematic execution, they DO NOT eliminate market risk. AI systems cannot predict black swan events, geopolitical crises, sudden market crashes, or unprecedented volatility spikes. Algorithmic trading is not a guarantee of profit and may experience periods of significant drawdown.
              </p>
            </section>

            <section className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">7. Technical & Infrastructure Risks</h2>
              <ul className="text-sm text-gray-300 space-y-2 ml-4">
                <li>• <strong>VPS/Server Failures:</strong> Power outages, hardware failures, or network connectivity issues can interrupt trading</li>
                <li>• <strong>MT5 Terminal Errors:</strong> Platform crashes, updates, or compatibility issues may affect EA operation</li>
                <li>• <strong>Broker Server Issues:</strong> Broker-side technical problems can cause order rejection or delays</li>
                <li>• <strong>Latency:</strong> Network delays can result in execution at different prices than expected</li>
                <li>• <strong>Data Feed Interruptions:</strong> Loss of price feed can prevent the EA from functioning correctly</li>
              </ul>
            </section>

            <section className="p-6 rounded-xl border border-amber-500/20 bg-amber-500/5">
              <h2 className="text-xl font-semibold text-amber-400 mb-3">8. Important Notice</h2>
              <p className="text-sm text-gray-300 leading-relaxed">
                By using THE GOLD MIND AI v2.0 PROFESSIONAL, you acknowledge that you have read, understood, and accept all risks associated with automated trading. You agree that THE GOLD MIND and its affiliates are not liable for any trading losses incurred. The Core Trading Engine operation on MetaTrader 5 is independent of this commercial website policy.
              </p>
            </section>
          </div>
        </div>
      </div>
    </main>
  );
}
