import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  Shield, Cpu, Brain, Globe, RefreshCw, Headphones,
  Lock, BarChart3, TrendingUp, AlertTriangle, CheckCircle2,
  ExternalLink, Award, Zap
} from 'lucide-react';

export default function HomePage() {
  const [showAlert, setShowAlert] = useState(true);
  const [animatedStats, setAnimatedStats] = useState({ winRate: 0, sharpe: 0, drawdown: 0, signals: 0 });

  useEffect(() => {
    const timer = setTimeout(() => {
      setAnimatedStats({ winRate: 68.4, sharpe: 1.82, drawdown: -4.2, signals: 847 });
    }, 500);
    return () => clearTimeout(timer);
  }, []);

  return (
    <main className="pt-16">
      {/* Investor Alert Banner */}
      {showAlert && (
        <div className="bg-amber-500/10 border-b border-amber-500/20 px-4 py-3">
          <div className="max-w-7xl mx-auto flex items-center justify-between">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-amber-400 flex-shrink-0" />
              <p className="text-xs text-amber-200">
                <strong>Investor Alert:</strong> THE GOLD MIND is available only via the official website. Beware of unauthorized sellers.
              </p>
            </div>
            <button onClick={() => setShowAlert(false)} className="text-amber-400 hover:text-amber-300 text-xs ml-4">
              Dismiss
            </button>
          </div>
        </div>
      )}

      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-amber-500/5 via-transparent to-transparent" />
        <div className="absolute top-20 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-amber-500/5 rounded-full blur-3xl" />
        
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24 md:py-32">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-amber-500/10 border border-amber-500/20 rounded-full mb-6">
              <Shield className="w-4 h-4 text-amber-400" />
              <span className="text-sm text-amber-400 font-medium">THE GOLD MIND AI v2.0 PROFESSIONAL</span>
            </div>
            
            <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold mb-6 leading-tight">
              <span className="text-white">Institutional</span>
              <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-400 to-amber-600">
                AI Trading Software
              </span>
            </h1>
            
            <p className="text-lg md:text-xl text-gray-400 max-w-3xl mx-auto mb-8">
              Systematic MetaTrader 5 automation with verified Core integrity, enterprise licensing, and global infrastructure.
            </p>

            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <Link
                to="/pricing"
                className="px-8 py-3 bg-amber-500 hover:bg-amber-400 text-black font-semibold rounded-lg transition-all shadow-lg shadow-amber-500/20"
              >
                View Pricing
              </Link>
              <Link
                to="/docs"
                className="px-8 py-3 border border-gray-700 hover:border-amber-500/50 text-gray-300 hover:text-amber-400 rounded-lg transition-all"
              >
                Read Documentation
              </Link>
            </div>

            <div className="mt-8 flex items-center justify-center gap-2">
              <a
                href="https://www.mql5.com/en/market/product/183685"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-amber-400 transition-colors"
              >
                <ExternalLink className="w-4 h-4" />
                Available on MQL5 Market
              </a>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Performance Stats */}
      <section className="py-16 border-y border-gray-800/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            <div className="text-center p-6 rounded-xl bg-gradient-to-b from-amber-500/5 to-transparent border border-amber-500/10">
              <div className="text-3xl md:text-4xl font-bold text-amber-400 mb-1">{animatedStats.winRate}%</div>
              <div className="text-sm text-gray-400">Win Rate</div>
              <div className="text-xs text-gray-500 mt-1">30-day rolling</div>
            </div>
            <div className="text-center p-6 rounded-xl bg-gradient-to-b from-amber-500/5 to-transparent border border-amber-500/10">
              <div className="text-3xl md:text-4xl font-bold text-amber-400 mb-1">{animatedStats.sharpe}</div>
              <div className="text-sm text-gray-400">Sharpe Ratio</div>
              <div className="text-xs text-gray-500 mt-1">Risk-adjusted</div>
            </div>
            <div className="text-center p-6 rounded-xl bg-gradient-to-b from-amber-500/5 to-transparent border border-amber-500/10">
              <div className="text-3xl md:text-4xl font-bold text-amber-400 mb-1">{animatedStats.drawdown}%</div>
              <div className="text-sm text-gray-400">Max Drawdown</div>
              <div className="text-xs text-gray-500 mt-1">Observed</div>
            </div>
            <div className="text-center p-6 rounded-xl bg-gradient-to-b from-amber-500/5 to-transparent border border-amber-500/10">
              <div className="text-3xl md:text-4xl font-bold text-amber-400 mb-1">{animatedStats.signals}</div>
              <div className="text-sm text-gray-400">AI Signals</div>
              <div className="text-xs text-gray-500 mt-1">This month</div>
            </div>
          </div>
          <p className="text-center text-xs text-gray-500 mt-4">
            * Performance data shown is historical backtest/example demo data for illustrative purposes only. Past performance does not guarantee future results. Verify live track record on{' '}
            <a href="https://www.myfxbook.com/portfolio/gold-mind-ai/12200748" target="_blank" rel="noopener noreferrer" className="text-amber-400 hover:text-amber-300 underline">Myfxbook</a>
            {' '}or MQL5 Market.
          </p>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Engineered for <span className="text-amber-400">professional traders</span>
            </h2>
            <p className="text-gray-400 max-w-2xl mx-auto">
              Every component is designed for reliability, transparency, and institutional-grade operation.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              { icon: Cpu, title: 'Verified Core Integrity', desc: 'SHA-256 verified trading core operating exclusively on MetaTrader 5 Professional.' },
              { icon: Brain, title: 'AI Signal Intelligence', desc: 'Advanced pattern recognition and systematic execution with institutional risk parameters.' },
              { icon: Shield, title: 'Enterprise Portal', desc: 'Unified licensing, downloads, device management, and subscription billing in one secure hub.' },
              { icon: Globe, title: 'Global Infrastructure', desc: 'Cloud-isolated commercial services with encrypted stores, audit trails, and health monitoring.' },
              { icon: RefreshCw, title: 'Professional Updates', desc: 'Checksum-verified installers and controlled release channels for every deployment.' },
              { icon: Headphones, title: 'Dedicated Support', desc: 'Knowledge base, ticket intake, and AI-assisted guidance for licensed customers worldwide.' },
            ].map((feature, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                className="p-6 rounded-xl bg-gradient-to-b from-white/[0.03] to-transparent border border-gray-800 hover:border-amber-500/30 transition-all group"
              >
                <feature.icon className="w-8 h-8 text-amber-400 mb-4 group-hover:scale-110 transition-transform" />
                <h3 className="text-lg font-semibold text-white mb-2">{feature.title}</h3>
                <p className="text-sm text-gray-400">{feature.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Strategy Overview */}
      <section className="py-24 bg-gradient-to-b from-transparent via-amber-500/[0.02] to-transparent">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Trading <span className="text-amber-400">Strategy</span> Overview
            </h2>
            <p className="text-gray-400 max-w-2xl mx-auto">
              High-level methodology for transparency. Detailed parameters available after licensing.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="p-8 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h3 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
                <BarChart3 className="w-5 h-5 text-amber-400" />
                Core Methodology
              </h3>
              <ul className="space-y-3">
                {[
                  'Multi-timeframe analysis (M15, H1, H4, D1)',
                  'Institutional order flow detection',
                  'Volatility-adjusted position sizing',
                  'Dynamic stop-loss & take-profit levels',
                  'News filter integration for high-impact events',
                ].map((item, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-amber-400 mt-0.5 flex-shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            <div className="p-8 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h3 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
                <Zap className="w-5 h-5 text-amber-400" />
                Risk Management
              </h3>
              <ul className="space-y-3">
                {[
                  'Maximum 2% risk per trade',
                  'Daily loss limit with auto-pause',
                  'Correlation-aware exposure limits',
                  'Spread & slippage protection',
                  'Equity-based drawdown circuit breaker',
                ].map((item, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-gray-300">
                    <CheckCircle2 className="w-4 h-4 text-amber-400 mt-0.5 flex-shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* System Requirements */}
      <section className="py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              System <span className="text-amber-400">Requirements</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h3 className="text-lg font-semibold text-amber-400 mb-4">Platform</h3>
              <ul className="space-y-2 text-sm text-gray-300">
                <li>• MetaTrader 5 (latest build)</li>
                <li>• Windows 10/11 or VPS</li>
                <li>• Internet connection (stable)</li>
                <li>• 2GB RAM minimum</li>
              </ul>
            </div>
            <div className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h3 className="text-lg font-semibold text-amber-400 mb-4">Broker</h3>
              <ul className="space-y-2 text-sm text-gray-300">
                <li>• Any MT5-compatible broker</li>
                <li>• ECN/Raw spread accounts preferred</li>
                <li>• XAUUSD symbol available</li>
                <li>• Min account: $500 recommended</li>
              </ul>
            </div>
            <div className="p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
              <h3 className="text-lg font-semibold text-amber-400 mb-4">Recommended</h3>
              <ul className="space-y-2 text-sm text-gray-300">
                <li>• VPS with &lt;5ms to broker</li>
                <li>• Dedicated IP address</li>
                <li>• 4GB+ RAM</li>
                <li>• SSD storage</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Verified Track Record */}
      <section className="py-24 bg-gradient-to-b from-transparent via-amber-500/[0.02] to-transparent">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Verified <span className="text-amber-400">Track Record</span>
            </h2>
            <p className="text-gray-400">Third-party verified performance monitoring</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto">
            <div className="p-8 rounded-xl border border-gray-800 bg-[#0d0d14] text-center">
              <ExternalLink className="w-10 h-10 text-amber-400 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-white mb-2">MQL5 Market</h3>
              <p className="text-sm text-gray-400 mb-4">
                Verified product listing with user reviews and signal data on the official MetaTrader marketplace.
              </p>
              <a
                href="https://www.mql5.com/en/market/product/183685"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2 border border-amber-500/30 hover:border-amber-500/60 text-amber-400 rounded-lg text-sm transition-all"
              >
                View on MQL5
                <ExternalLink className="w-3 h-3" />
              </a>
            </div>

            <div className="p-8 rounded-xl border border-gray-800 bg-[#0d0d14] text-center">
              <BarChart3 className="w-10 h-10 text-amber-400 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-white mb-2">Myfxbook Verified</h3>
              <p className="text-sm text-gray-400 mb-4">
                Live verified trading account results with real-time performance tracking and third-party verification.
              </p>
              <a
                href="https://www.myfxbook.com/portfolio/gold-mind-ai/12200748"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2 border border-amber-500/30 hover:border-amber-500/60 text-amber-400 rounded-lg text-sm transition-all"
              >
                View Live Track Record
                <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          </div>

          <p className="text-center text-xs text-gray-500 mt-8 max-w-2xl mx-auto">
            All performance claims should be independently verified through third-party tracking services. 
            THE GOLD MIND encourages all prospective users to review verified track records before making any purchasing decisions.
          </p>
        </div>
      </section>

      {/* Trust & Security */}
      <section className="py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Built for <span className="text-amber-400">institutional confidence</span>
            </h2>
            <p className="text-gray-400 max-w-2xl mx-auto">
              Every layer of THE GOLD MIND ecosystem is engineered for transparency, security, and professional operation.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { icon: Shield, title: 'Verified MT5 Technology', desc: 'Tested Expert Advisor on MetaTrader 5 Professional.' },
              { icon: Brain, title: 'AI Infrastructure', desc: 'Enterprise-grade signal processing and risk-aware automation.' },
              { icon: Lock, title: 'Enterprise Security', desc: 'Encrypted licensing, audit trails, and hardened cloud isolation.' },
              { icon: Award, title: 'Compliance Ready', desc: 'Enterprise documentation, legal surfaces, and audit workflows.' },
              { icon: TrendingUp, title: 'Risk Management', desc: 'Built-in safeguards separate from the verified Core engine.' },
              { icon: Globe, title: 'Global Availability', desc: 'International deployment with regional compliance readiness.' },
              { icon: RefreshCw, title: 'Verified Updates', desc: 'SHA-256 checksums on every release package.' },
              { icon: Headphones, title: 'Professional Support', desc: 'Dedicated support center with ticket intake and knowledge base.' },
            ].map((item, i) => (
              <div key={i} className="p-5 rounded-xl border border-gray-800/50 hover:border-amber-500/20 transition-all">
                <item.icon className="w-6 h-6 text-amber-400 mb-3" />
                <h4 className="text-sm font-semibold text-white mb-1">{item.title}</h4>
                <p className="text-xs text-gray-400">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="p-12 rounded-2xl bg-gradient-to-b from-amber-500/10 to-transparent border border-amber-500/20">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Begin your <span className="text-amber-400">professional journey</span>
            </h2>
            <p className="text-gray-400 mb-8">
              License THE GOLD MIND through the official Customer Portal. Trading involves substantial risk of loss.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <Link
                to="/pricing"
                className="px-8 py-3 bg-amber-500 hover:bg-amber-400 text-black font-semibold rounded-lg transition-all shadow-lg shadow-amber-500/20"
              >
                View Pricing
              </Link>
              <Link
                to="/docs"
                className="px-8 py-3 border border-gray-700 hover:border-amber-500/50 text-gray-300 hover:text-amber-400 rounded-lg transition-all"
              >
                Read Documentation
              </Link>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
