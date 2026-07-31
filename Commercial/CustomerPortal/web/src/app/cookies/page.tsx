import { LegalShell } from "@/components/enterprise/LegalShell";
import { brand } from "@/lib/brand";

export default function CookiesPage() {
  return (
    <LegalShell title="Cookie Policy">
      <p>
        <strong>Status:</strong> Production draft — OWNER REVIEW REQUIRED before open commercial launch.
        Effective date (draft): 31 July 2026.
      </p>

      <h2>1. What Are Cookies</h2>
      <p>
        Cookies and similar technologies store small pieces of data in your browser to operate the site and Customer
        Portal securely.
      </p>

      <h2>2. Essential Cookies</h2>
      <p>
        Authentication and session cookies are required for login, CSRF protections, and secure portal access. These
        cannot be disabled if you use the Customer Portal.
      </p>

      <h2>3. Analytics and Marketing</h2>
      <p>
        Analytics/marketing cookies are not enabled by default in the commercial portal build. If introduced later,
        they will be disclosed and, where required, gated by consent.
      </p>

      <h2>4. Managing Cookies</h2>
      <p>
        You can clear or block cookies in your browser settings. Blocking essential cookies will prevent portal
        login.
      </p>

      <h2>5. Contact</h2>
      <p>
        <a href={`mailto:${brand.emails.privacy}`}>{brand.emails.privacy}</a>
      </p>
    </LegalShell>
  );
}
