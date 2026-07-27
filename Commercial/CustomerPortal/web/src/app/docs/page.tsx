import type { Metadata } from "next";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { DocsClient } from "@/components/enterprise/DocsClient";

export const metadata: Metadata = {
  title: "Documentation — THE GOLD MIND PROFESSIONAL",
  description: "Enterprise documentation portal — guides, FAQ, developer docs, and knowledge base for THE GOLD MIND.",
};

export default function DocsPage() {
  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container" style={{ paddingBottom: 0 }}>
        <ScrollReveal>
          <p className="e-eyebrow">Knowledge Base</p>
          <h1 className="e-section-title">Documentation</h1>
          <p className="e-section-sub">Guides, FAQ, and developer resources for THE GOLD MIND AI v2.0 PROFESSIONAL.</p>
        </ScrollReveal>
      </div>
      <DocsClient />
    </EnterpriseShell>
  );
}
