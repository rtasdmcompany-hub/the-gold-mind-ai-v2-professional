import type { Metadata } from "next";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { ScrollReveal } from "@/components/enterprise/ScrollReveal";
import { DocsClient } from "@/components/enterprise/DocsClient";
import { brand } from "@/lib/brand";

export const metadata: Metadata = {
  title: `Documentation — ${brand.productName}`,
  description: `Enterprise documentation portal — guides, FAQ, developer docs, and knowledge base for ${brand.brandName}.`,
};

export default function DocsPage() {
  return (
    <EnterpriseShell>
      <div className="e-page-hero e-container" style={{ paddingBottom: 0 }}>
        <ScrollReveal>
          <p className="e-eyebrow">Knowledge Base</p>
          <h1 className="e-section-title">Documentation</h1>
          <p className="e-section-sub">Guides, FAQ, and developer resources for {brand.productFullName}.</p>
        </ScrollReveal>
      </div>
      <DocsClient />
    </EnterpriseShell>
  );
}
