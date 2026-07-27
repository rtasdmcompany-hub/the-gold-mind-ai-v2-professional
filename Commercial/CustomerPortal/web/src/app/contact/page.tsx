import type { Metadata } from "next";
import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";

export const metadata: Metadata = {
  title: "Contact — THE GOLD MIND PROFESSIONAL",
  description: "Contact RTAS Digital Marketing Company for THE GOLD MIND PROFESSIONAL commercial inquiries.",
};

export default function ContactPage() {
  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">Get in Touch</p>
          <h1 className="e-section-title">Contact</h1>
          <p className="e-section-sub">
            For licensed customers, open a ticket in the{" "}
            <Link href="/login">Customer Portal → Support</Link>. For commercial inquiries use the form below.
          </p>
        </ScrollReveal>
      </div>

      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 560 }}>
          <ScrollReveal>
            <form className="e-glass-card e-form" action="/api/contact" method="post">
              <div className="e-field">
                <label htmlFor="name">Name</label>
                <input id="name" name="name" required autoComplete="name" />
              </div>
              <div className="e-field">
                <label htmlFor="email">Email</label>
                <input id="email" name="email" type="email" required autoComplete="email" />
              </div>
              <div className="e-field">
                <label htmlFor="message">Message</label>
                <textarea id="message" name="message" rows={5} required />
              </div>
              <button type="submit" className="e-btn e-btn-primary">
                Send Message
              </button>
              <p style={{ fontSize: 12, color: "var(--e-text-dim)", margin: 0 }}>
                Logged to commercial support intake. Do not send license keys in clear text.
              </p>
            </form>
          </ScrollReveal>
          <p style={{ marginTop: 24, fontSize: 13, color: "var(--e-text-dim)", textAlign: "center" }}>
            Legal entity: RTAS Group of Companies · Division RTAS Digital Marketing Company
          </p>
        </div>
      </section>
    </EnterpriseShell>
  );
}
