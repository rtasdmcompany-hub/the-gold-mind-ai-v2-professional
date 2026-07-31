import { LegalShell } from "@/components/enterprise/LegalShell";
import { brand } from "@/lib/brand";

export default function RefundPage() {
  return (
    <LegalShell title="Refund Policy">
      <p>
        <strong>Status:</strong> Production draft — OWNER REVIEW REQUIRED before open commercial launch.
        Effective date (draft): 31 July 2026.
      </p>

      <h2>1. Trials</h2>
      <p>Trial plans are not billed. No refund is applicable to unpaid trials.</p>

      <h2>2. Subscriptions (Monthly / Yearly)</h2>
      <p>
        Refund eligibility depends on time since purchase and whether the license has been activated/downloaded.
        Unless mandatory consumer law requires otherwise, refund requests should be submitted within fourteen (14)
        days of purchase to <a href={`mailto:${brand.emails.billing}`}>{brand.emails.billing}</a> with your order or invoice
        reference.
      </p>

      <h2>3. Lifetime Licenses</h2>
      <p>
        Lifetime licenses are refundable only as required by applicable law or as expressly approved by {brand.companyName} in
        writing for exceptional cases (e.g. verified duplicate charge).
      </p>

      <h2>4. How Refunds Are Paid</h2>
      <p>
        Approved refunds are processed through Paddle (or the original payment provider) and follow that provider’s
        settlement timelines. Chargebacks should be a last resort; contact billing first.
      </p>

      <h2>5. Abuse</h2>
      <p>
        Refunds may be denied where we reasonably detect fraud, key sharing, or repeated purchase/refund abuse.
      </p>
    </LegalShell>
  );
}
