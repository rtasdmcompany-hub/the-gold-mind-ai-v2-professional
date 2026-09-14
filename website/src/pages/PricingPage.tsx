import { Link } from 'react-router-dom';
import { Check, Star } from 'lucide-react';

export default function PricingPage() {
  const plans = [
    {
      name: 'Professional Trial',
      price: 'Free',
      period: '/14 days',
      features: [
        'MT5 Expert Advisor (.ex5 binary)',
        'Core Gold (XAUUSD) Strategy Access',
        'Built-in Risk Management Controls',
        'Customer Portal & License Manager',
        'Checksum-verified installer downloads',
        'Installation Guide & Documentation',
      ],
      recommended: false,
    },
    {
      name: 'Professional Monthly',
      price: '$99',
      period: '/month',
      features: [
        'MT5 Expert Advisor (.ex5 binary)',
        'Core Gold (XAUUSD) Strategy Access',
        'Built-in Risk Management Controls',
        'Customer Portal & License Manager',
        'Checksum-verified installer downloads',
        'Automatic Strategy Updates',
        'Customer Support Access',
      ],
      recommended: false,
    },
    {
      name: 'Professional Yearly',
      price: '$899',
      period: '/year',
      features: [
        'MT5 Expert Advisor (.ex5 binary)',
        'Core Gold (XAUUSD) Strategy Access',
        'Built-in Risk Management Controls',
        'Customer Portal & License Manager',
        'Checksum-verified installer downloads',
        'Automatic Strategy Updates',
        'Knowledge Base & Installation Guide',
        'Priority Customer Support',
      ],
      recommended: true,
    },
    {
      name: 'Professional Lifetime',
      price: '$2,499',
      period: '/once',
      features: [
        'MT5 Expert Advisor (.ex5 binary)',
        'Core Gold (XAUUSD) Strategy Access',
        'Built-in Risk Management Controls',
        'Customer Portal & License Manager',
        'Checksum-verified installer downloads',
        'All Future Strategy Updates',
        'Lifetime Priority Support',
        'Early Access to New Features',
      ],
      recommended: false,
    },
  ];

  return (
    <main className="pt-24 pb-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            Professional <span className="text-amber-400">Pricing</span>
          </h1>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Enterprise licensing via Customer Portal. No guaranteed profits. Past performance is not indicative of future results.
          </p>
        </div>

        {/* Plans Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
          {plans.map((plan, i) => (
            <div
              key={i}
              className={`relative p-6 rounded-xl border transition-all ${
                plan.recommended
                  ? 'border-amber-500/50 bg-gradient-to-b from-amber-500/10 to-transparent shadow-lg shadow-amber-500/5'
                  : 'border-gray-800 bg-[#0d0d14] hover:border-gray-700'
              }`}
            >
              {plan.recommended && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 bg-amber-500 text-black text-xs font-bold rounded-full">
                  RECOMMENDED
                </div>
              )}
              <h3 className="text-lg font-semibold text-white mb-2">{plan.name}</h3>
              <div className="mb-6">
                <span className="text-3xl font-bold text-amber-400">{plan.price}</span>
                <span className="text-gray-400 text-sm">{plan.period}</span>
              </div>
              <ul className="space-y-3 mb-8">
                {plan.features.map((feature, j) => (
                  <li key={j} className="flex items-start gap-2 text-sm text-gray-300">
                    <Check className="w-4 h-4 text-amber-400 mt-0.5 flex-shrink-0" />
                    {feature}
                  </li>
                ))}
              </ul>
              <Link
                to="/contact"
                className={`block text-center py-2.5 rounded-lg font-semibold text-sm transition-all ${
                  plan.recommended
                    ? 'bg-amber-500 hover:bg-amber-400 text-black'
                    : 'border border-gray-700 hover:border-amber-500/50 text-gray-300 hover:text-amber-400'
                }`}
              >
                {plan.name.includes('Trial') ? 'Start Free Trial' : 'Get Access'}
              </Link>
            </div>
          ))}
        </div>

        {/* Feature Comparison Table */}
        <div className="mb-16">
          <h2 className="text-2xl font-bold text-center mb-8">
            Feature <span className="text-amber-400">Comparison</span>
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-800">
                  <th className="text-left py-3 px-4 text-gray-400 font-medium">Feature</th>
                  <th className="text-center py-3 px-4 text-gray-400 font-medium">Trial</th>
                  <th className="text-center py-3 px-4 text-gray-400 font-medium">Monthly</th>
                  <th className="text-center py-3 px-4 text-amber-400 font-medium">Yearly</th>
                  <th className="text-center py-3 px-4 text-gray-400 font-medium">Lifetime</th>
                </tr>
              </thead>
              <tbody>
                {[
                  { feature: 'MT5 Expert Advisor (.ex5)', trial: true, monthly: true, yearly: true, lifetime: true },
                  { feature: 'Customer Portal', trial: true, monthly: true, yearly: true, lifetime: true },
                  { feature: 'Device activation', trial: true, monthly: true, yearly: true, lifetime: true },
                  { feature: 'Installer downloads', trial: true, monthly: true, yearly: true, lifetime: true },
                  { feature: 'Update pipeline', trial: true, monthly: true, yearly: true, lifetime: true },
                  { feature: 'Priority support', trial: false, monthly: false, yearly: true, lifetime: true },
                  { feature: 'AI assistant', trial: false, monthly: false, yearly: true, lifetime: false },
                  { feature: 'Lifetime updates', trial: false, monthly: false, yearly: false, lifetime: true },
                ].map((row, i) => (
                  <tr key={i} className="border-b border-gray-800/50">
                    <td className="py-3 px-4 text-gray-300">{row.feature}</td>
                    <td className="text-center py-3 px-4">{row.trial ? <span className="text-amber-400">✓</span> : <span className="text-gray-600">—</span>}</td>
                    <td className="text-center py-3 px-4">{row.monthly ? <span className="text-amber-400">✓</span> : <span className="text-gray-600">—</span>}</td>
                    <td className="text-center py-3 px-4">{row.yearly ? <span className="text-amber-400">✓</span> : <span className="text-gray-600">—</span>}</td>
                    <td className="text-center py-3 px-4">{row.lifetime ? <span className="text-amber-400">✓</span> : <span className="text-gray-600">—</span>}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Refund Policy */}
        <div className="max-w-3xl mx-auto p-6 rounded-xl border border-gray-800 bg-[#0d0d14]">
          <h3 className="text-lg font-semibold text-white mb-3 flex items-center gap-2">
            <Star className="w-5 h-5 text-amber-400" />
            Refund Policy
          </h3>
          <p className="text-sm text-gray-400 mb-2">
            Due to the digital nature of this software, all sales are final once the license key has been activated. 
            However, we offer a 14-day free trial so you can evaluate the software before purchasing.
          </p>
          <p className="text-sm text-gray-400">
            If you experience technical issues preventing activation or operation, contact support within 7 days of purchase for assistance.
          </p>
        </div>
      </div>
    </main>
  );
}
