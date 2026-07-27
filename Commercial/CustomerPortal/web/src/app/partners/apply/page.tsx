import Link from "next/link";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { actionSubmitPartnerApplication } from "@/server/partners/actions";

export default function PartnerApplyPage() {
  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">Partner Network</p>
          <h1 className="e-section-title">Partner Application</h1>
          <p className="e-section-sub">
            Join the THE GOLD MIND Professional partner network · commercial channel only
          </p>
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container" style={{ maxWidth: 560 }}>
          <ScrollReveal>
            <form action={actionSubmitPartnerApplication} className="e-glass-card e-form">
              <div className="e-field">
                <label htmlFor="name">Name</label>
                <input id="name" name="name" required />
              </div>
              <div className="e-field">
                <label htmlFor="email">Email</label>
                <input id="email" name="email" type="email" required />
              </div>
              <div className="e-field">
                <label htmlFor="company">Company</label>
                <input id="company" name="company" />
              </div>
              <div className="e-field">
                <label htmlFor="region">Region</label>
                <input id="region" name="region" />
              </div>
              <div className="e-field">
                <label htmlFor="country">Country</label>
                <input id="country" name="country" />
              </div>
              <div className="e-field">
                <label htmlFor="website">Website</label>
                <input id="website" name="website" />
              </div>
              <div className="e-field">
                <label htmlFor="pitch">Pitch</label>
                <textarea id="pitch" name="pitch" required rows={4} />
              </div>
              <button type="submit" className="e-btn e-btn-primary">
                Submit Application
              </button>
            </form>
            <p style={{ marginTop: 20, textAlign: "center" }}>
              <Link href="/">Back to site</Link>
            </p>
          </ScrollReveal>
        </div>
      </section>
    </EnterpriseShell>
  );
}
