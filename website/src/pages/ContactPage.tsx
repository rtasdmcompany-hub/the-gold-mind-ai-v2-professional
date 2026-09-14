import { useState } from 'react';
import { Mail, MessageSquare, Send, CheckCircle } from 'lucide-react';

export default function ContactPage() {
  const [submitted, setSubmitted] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', message: '' });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
  };

  return (
    <main className="pt-24 pb-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            Get in <span className="text-amber-400">Touch</span>
          </h1>
          <p className="text-gray-400 max-w-2xl mx-auto">
            For licensed customers, open a ticket in the Customer Portal. For commercial inquiries, use the form below.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 max-w-5xl mx-auto">
          {/* Contact Info */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-6">Contact Information</h2>
            
            <div className="space-y-6">
              <div className="flex items-start gap-4 p-4 rounded-xl border border-gray-800 bg-[#0d0d14]">
                <Mail className="w-5 h-5 text-amber-400 mt-0.5" />
                <div>
                  <h3 className="text-sm font-semibold text-white">General Support</h3>
                  <p className="text-sm text-gray-400">support@thegoldmind.ai</p>
                </div>
              </div>

              <div className="flex items-start gap-4 p-4 rounded-xl border border-gray-800 bg-[#0d0d14]">
                <Mail className="w-5 h-5 text-amber-400 mt-0.5" />
                <div>
                  <h3 className="text-sm font-semibold text-white">Billing & Licensing</h3>
                  <p className="text-sm text-gray-400">billing@thegoldmind.ai</p>
                </div>
              </div>

              <div className="flex items-start gap-4 p-4 rounded-xl border border-gray-800 bg-[#0d0d14]">
                <MessageSquare className="w-5 h-5 text-amber-400 mt-0.5" />
                <div>
                  <h3 className="text-sm font-semibold text-white">Customer Portal</h3>
                  <p className="text-sm text-gray-400">Licensed users: Portal → Support → New Ticket</p>
                </div>
              </div>
            </div>

            <div className="mt-8 p-4 rounded-xl border border-amber-500/20 bg-amber-500/5">
              <p className="text-sm text-amber-200">
                <strong>Security Note:</strong> Never share your license key, portal password, or broker credentials via email or chat.
              </p>
            </div>
          </div>

          {/* Contact Form */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-6">Send a Message</h2>
            
            {submitted ? (
              <div className="p-8 rounded-xl border border-green-500/30 bg-green-500/5 text-center">
                <CheckCircle className="w-12 h-12 text-green-400 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-white mb-2">Message Sent</h3>
                <p className="text-sm text-gray-400">
                  Thank you for reaching out. Our team will respond within 24-48 business hours.
                </p>
                <button
                  onClick={() => { setSubmitted(false); setForm({ name: '', email: '', message: '' }); }}
                  className="mt-4 text-sm text-amber-400 hover:text-amber-300"
                >
                  Send another message
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1">Name</label>
                  <input
                    type="text"
                    required
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    className="w-full px-4 py-2.5 bg-[#0d0d14] border border-gray-800 rounded-lg text-white text-sm focus:border-amber-500/50 focus:outline-none transition-colors"
                    placeholder="Your full name"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1">Email</label>
                  <input
                    type="email"
                    required
                    value={form.email}
                    onChange={(e) => setForm({ ...form, email: e.target.value })}
                    className="w-full px-4 py-2.5 bg-[#0d0d14] border border-gray-800 rounded-lg text-white text-sm focus:border-amber-500/50 focus:outline-none transition-colors"
                    placeholder="your@email.com"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1">Message</label>
                  <textarea
                    required
                    rows={5}
                    value={form.message}
                    onChange={(e) => setForm({ ...form, message: e.target.value })}
                    className="w-full px-4 py-2.5 bg-[#0d0d14] border border-gray-800 rounded-lg text-white text-sm focus:border-amber-500/50 focus:outline-none transition-colors resize-none"
                    placeholder="How can we help you?"
                  />
                </div>
                <button
                  type="submit"
                  className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-amber-500 hover:bg-amber-400 text-black font-semibold rounded-lg transition-all"
                >
                  <Send className="w-4 h-4" />
                  Send Message
                </button>
                <p className="text-xs text-gray-500 text-center">
                  Logged to commercial support intake. Do not send license keys in clear text.
                </p>
              </form>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
