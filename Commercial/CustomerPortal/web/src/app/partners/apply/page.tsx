import Link from "next/link";
import { actionSubmitPartnerApplication } from "@/server/partners/actions";

export default function PartnerApplyPage() {
  return (
    <main style={{ maxWidth: 640, margin: "40px auto", padding: 24 }}>
      <h1 className="page-title">Partner Application</h1>
      <p className="page-sub">
        Join the THE GOLD MIND Professional partner network · commercial channel only
      </p>
      <form action={actionSubmitPartnerApplication} className="card" style={{ padding: 20 }}>
        <label>
          Name
          <input name="name" required style={{ display: "block", width: "100%", marginBottom: 12 }} />
        </label>
        <label>
          Email
          <input
            name="email"
            type="email"
            required
            style={{ display: "block", width: "100%", marginBottom: 12 }}
          />
        </label>
        <label>
          Company
          <input name="company" style={{ display: "block", width: "100%", marginBottom: 12 }} />
        </label>
        <label>
          Region
          <input name="region" style={{ display: "block", width: "100%", marginBottom: 12 }} />
        </label>
        <label>
          Country
          <input name="country" style={{ display: "block", width: "100%", marginBottom: 12 }} />
        </label>
        <label>
          Website
          <input name="website" style={{ display: "block", width: "100%", marginBottom: 12 }} />
        </label>
        <label>
          Pitch
          <textarea
            name="pitch"
            required
            rows={4}
            style={{ display: "block", width: "100%", marginBottom: 12 }}
          />
        </label>
        <button type="submit" className="btn btn-primary">
          Submit application
        </button>
      </form>
      <p style={{ marginTop: 16 }}>
        <Link href="/">Back to site</Link>
      </p>
    </main>
  );
}
