import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import HomePage from './pages/HomePage';
import PricingPage from './pages/PricingPage';
import DocsPage from './pages/DocsPage';
import ContactPage from './pages/ContactPage';
import RiskPage from './pages/RiskPage';
import DisclaimerPage from './pages/DisclaimerPage';
import PrivacyPage from './pages/PrivacyPage';
import TermsPage from './pages/TermsPage';

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-[#0a0a0f] text-white font-sans">
        <Navbar />
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/pricing" element={<PricingPage />} />
          <Route path="/docs" element={<DocsPage />} />
          <Route path="/contact" element={<ContactPage />} />
          <Route path="/risk" element={<RiskPage />} />
          <Route path="/disclaimer" element={<DisclaimerPage />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="/terms" element={<TermsPage />} />
        </Routes>
        <Footer />
      </div>
    </Router>
  );
}

export default App;
