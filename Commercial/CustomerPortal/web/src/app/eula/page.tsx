import { LegalShell } from "@/components/enterprise/LegalShell";

export default function EulaPage() {
  return (
    <LegalShell title="End User License Agreement (EULA)">
      <p>
        <strong>Status:</strong> Production draft — OWNER REVIEW REQUIRED before open commercial launch.
        Effective date (draft): 31 July 2026.
      </p>

      <h2>1. License Grant</h2>
      <p>
        Subject to a valid paid or trial license, RTAS grants you a limited, non-exclusive, non-transferable,
        revocable license to install and use THE GOLD MIND PROFESSIONAL Expert Advisor and accompanying commercial
        installer components on authorized devices up to your seat limit.
      </p>

      <h2>2. Restrictions</h2>
      <ul>
        <li>No sublicensing, rental, or public redistribution of binaries or license keys</li>
        <li>No circumvention of activation, device binding, or update integrity checks</li>
        <li>No reverse engineering except where mandatory law prohibits this restriction</li>
        <li>No use that violates broker, exchange, or applicable financial regulations</li>
      </ul>

      <h2>3. Ownership</h2>
      <p>
        RTAS retains all rights in the software, documentation, trademarks, and related materials. This EULA does
        not transfer ownership.
      </p>

      <h2>4. Updates</h2>
      <p>
        Updates may be delivered through the Customer Portal or installer update channel. Continued use after an
        update constitutes acceptance of the then-current EULA unless a separate agreement applies.
      </p>

      <h2>5. Termination</h2>
      <p>
        The license ends when your subscription expires or is cancelled, or immediately upon material breach. Upon
        termination you must cease use and destroy distributed copies remaining under your control.
      </p>

      <h2>6. Disclaimer</h2>
      <p>
        Software is provided “as is” to the extent permitted by law. Trading results are not guaranteed. See the
        Disclaimer and Risk Disclosure.
      </p>

      <h2>7. Contact</h2>
      <p>
        <a href="mailto:legal@rtas.group">legal@rtas.group</a>
      </p>
    </LegalShell>
  );
}
