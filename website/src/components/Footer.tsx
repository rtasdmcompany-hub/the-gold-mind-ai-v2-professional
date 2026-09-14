import { Link } from 'react-router-dom';
import { Shield } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-[#060609] border-t border-amber-500/10 pt-16 pb-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-1 md:col-span-2">
            <div className="flex items-center gap-2 mb-4">
              <Shield className="w-6 h-6 text-amber-400" />
              <span className="text-lg font-bold">
                <span className="text-amber-400">THE GOLD</span>{' '}
                <span className="text-white">MIND</span>
              </span>
            </div>
            <p className="text-gray-400 text-sm max-w-md mb-4">
              Institutional AI Trading Software for MetaTrader 5. Verified Core Engine with enterprise licensing, AI signal intelligence, and global infrastructure.
            </p>
            <p className="text-xs text-gray-500">
              Trading involves substantial risk of loss. Past performance does not guarantee future results.
            </p>
          </div>

          {/* Product */}
          <div>
            <h4 className="text-sm font-semibold text-amber-400 mb-3 uppercase tracking-wider">Product</h4>
            <ul className="space-y-2">
              <li><Link to="/pricing" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">Pricing</Link></li>
              <li><Link to="/docs" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">Documentation</Link></li>
              <li><Link to="/contact" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">Contact</Link></li>
              <li>
                <a href="https://www.mql5.com/en/market/product/183685" target="_blank" rel="noopener noreferrer" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">
                  MQL5 Market
                </a>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h4 className="text-sm font-semibold text-amber-400 mb-3 uppercase tracking-wider">Legal</h4>
            <ul className="space-y-2">
              <li><Link to="/risk" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">Risk Disclosure</Link></li>
              <li><Link to="/disclaimer" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">Disclaimer</Link></li>
              <li><Link to="/privacy" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">Privacy Policy</Link></li>
              <li><Link to="/terms" className="text-sm text-gray-400 hover:text-amber-400 transition-colors">Terms of Service</Link></li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="border-t border-gray-800 pt-6 flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="text-center md:text-left">
            <p className="text-xs text-gray-500">
              © {new Date().getFullYear()} THE GOLD MIND PROFESSIONAL. All rights reserved.
            </p>
            <p className="text-xs text-gray-600 mt-1">
              THE GOLD MIND AI PROFESSIONAL is developed and operated by RTAS Digital Marketing Company.
            </p>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-xs text-gray-500">support@thegoldmind.ai</span>
            <span className="text-xs text-gray-500">billing@thegoldmind.ai</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
