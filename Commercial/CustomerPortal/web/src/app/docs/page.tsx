import type { Metadata } from "next";
import Link from "next/link";
import { SiteNav } from "@/components/SiteNav";

export const metadata: Metadata = {
  title: "Documentation — THE GOLD MIND PROFESSIONAL",
  description: "Documentation hub for THE GOLD MIND PROFESSIONAL Website Edition.",
};

export default function DocsPage() {
  return (
    <div>
      <SiteNav />
      <main style={{ maxWidth: 720, margin: "0 auto", padding: "48px 24px 80px" }}>
        <p className="brand-mark">THE GOLD MIND PROFESSIONAL</p>
        <h1 style={{ fontFamily: "Georgia, serif", fontSize: 40, fontWeight: 400 }}>Documentation</h1>
        <p style={{ color: "var(--gm-ivory-300)" }}>
          Customer guides live in the Portal Knowledge Base after sign-in. Public legal and risk pages:
        </p>
        <ul style={{ lineHeight: 1.9 }}>
          <li>
            <Link href="/risk">Risk disclosure</Link>
          </li>
          <li>
            <Link href="/privacy">Privacy policy (draft)</Link>
          </li>
          <li>
            <Link href="/terms">Terms / EULA (draft)</Link>
          </li>
          <li>
            <Link href="/refund">Refund policy (draft)</Link>
          </li>
          <li>
            <Link href="/cookies">Cookie policy (draft)</Link>
          </li>
          <li>
            <Link href="/login">Customer Portal → Knowledge Base</Link>
          </li>
        </ul>
      </main>
    </div>
  );
}
