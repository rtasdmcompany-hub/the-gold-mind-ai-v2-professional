import { LegalShell } from "@/components/enterprise/LegalShell";

export default function TermsPage() {
  return (
    <LegalShell title="Terms of Service / EULA">
      <p>
        License grant is personal/non-transferable per purchased seat. Acceptable use excludes reverse engineering of
        the commercial portal and unauthorized redistribution of installer packages.
      </p>
      <p>Trading involves risk of loss. THE GOLD MIND does not guarantee profits.</p>
      <h2>License Scope</h2>
      <p>
        Each license binds to authorized devices per plan limits. Sharing license keys violates these terms and may
        result in revocation.
      </p>
    </LegalShell>
  );
}
