import type { Metadata } from "next";
import Link from "next/link";
import { SiteNav } from "@/components/SiteNav";

export const metadata: Metadata = {
  title: "Contact — THE GOLD MIND PROFESSIONAL",
  description: "Contact RTAS Digital Marketing Company for THE GOLD MIND PROFESSIONAL Website Edition support.",
};

export default function ContactPage() {
  return (
    <div>
      <SiteNav />
      <main style={{ maxWidth: 640, margin: "0 auto", padding: "48px 24px 80px" }}>
        <p className="brand-mark">THE GOLD MIND PROFESSIONAL</p>
        <h1 style={{ fontFamily: "Georgia, serif", fontSize: 40, fontWeight: 400 }}>Contact</h1>
        <p style={{ color: "var(--gm-ivory-300)" }}>
          For licensed customers, open a ticket in the{" "}
          <Link href="/login">Customer Portal → Support</Link>. For commercial inquiries use the form below.
        </p>
        <form
          className="card"
          style={{ marginTop: 24, padding: 24, display: "grid", gap: 12 }}
          action="/api/contact"
          method="post"
        >
          <label>
            Name
            <input name="name" required style={{ display: "block", width: "100%", marginTop: 4 }} />
          </label>
          <label>
            Email
            <input name="email" type="email" required style={{ display: "block", width: "100%", marginTop: 4 }} />
          </label>
          <label>
            Message
            <textarea name="message" required rows={5} style={{ display: "block", width: "100%", marginTop: 4 }} />
          </label>
          <button type="submit" className="btn btn-primary">
            Send message
          </button>
          <p className="meta">Logged to commercial support intake. Do not send license keys in clear text.</p>
        </form>
        <p className="meta" style={{ marginTop: 20 }}>
          Legal entity: RTAS Group of Companies · Division RTAS Digital Marketing Company (address pending BC-LEGAL).
        </p>
      </main>
    </div>
  );
}
