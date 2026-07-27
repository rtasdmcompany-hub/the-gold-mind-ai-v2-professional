import { LegalShell } from "@/components/enterprise/LegalShell";

export default function PrivacyPage() {
  return (
    <LegalShell title="Privacy Policy">
      <p>
        RTAS processes account email, license metadata, device binding hashes, support tickets, and payment references
        via PSP processors (e.g. Paddle/PayPal). Card data is never stored on THE GOLD MIND portal.
      </p>
      <h2>Data We Process</h2>
      <p>
        Account credentials, license keys (encrypted), device fingerprints, audit logs, support communications, and
        billing references.
      </p>
      <h2>Contact</h2>
      <p>
        Contact: legal@rtas.local (placeholder). Full counsel-approved text will replace this draft before public Stable.
      </p>
    </LegalShell>
  );
}
