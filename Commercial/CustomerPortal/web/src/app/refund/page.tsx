import { LegalShell } from "@/components/enterprise/LegalShell";

export default function RefundPage() {
  return (
    <LegalShell title="Refund Policy">
      <p>
        Refund eligibility depends on your plan and the time elapsed since purchase. Trial plans are not billed.
        Monthly and yearly subscriptions may be eligible for a refund within the applicable window; lifetime
        licenses are refundable only as required by applicable law.
      </p>
      <p>
        Refunds are processed through our payment provider (Paddle) and follow their standard settlement
        timelines. To request a refund, contact{" "}
        <a href="mailto:billing@rtas.group">billing@rtas.group</a> with your order or invoice reference.
      </p>
    </LegalShell>
  );
}
