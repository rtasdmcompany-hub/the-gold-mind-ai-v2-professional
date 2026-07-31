import type { Metadata } from "next";
import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { brand } from "@/lib/brand";
import { brandPageMetadata } from "@/lib/brand-metadata";

export const metadata: Metadata = brandPageMetadata({
  title: "Contact",
  description: `Contact ${brand.brandName} for ${brand.productName} commercial inquiries.`,
});

export default async function ContactPage({
  searchParams,
}: {
  searchParams: Promise<{ sent?: string }>;
}) {
  const sp = await searchParams;
  const sent = sp.sent === "1";

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
            {sent ? (
              <div className="e-glass-card" role="status">
                <h2 style={{ marginTop: 0 }}>Message sent</h2>
                <p>
                  Thank you — your message has been received. Our team will get back to you shortly at the email
                  address you provided.
                </p>
                <p style={{ fontSize: 13, marginBottom: 0 }}>
                  <Link href="/contact">Send another message</Link>
                </p>
              </div>
            ) : (
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
            )}
          </ScrollReveal>
          <p style={{ marginTop: 24, fontSize: 13, color: "var(--e-text-dim)", textAlign: "center" }}>
            Product: {brand.brandName} · {brand.emails.support} · {brand.emails.billing}
          </p>
        </div>
      </section>
    </EnterpriseShell>
  );
}
