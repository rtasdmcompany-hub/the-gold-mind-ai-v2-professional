import { brand } from "@/lib/brand";
export default function GlobalLoading() {
  return (
    <div className="e-container" style={{ maxWidth: 560, padding: "96px 24px", textAlign: "center" }}>
      <p className="e-eyebrow">{brand.productName}</p>
      <p className="e-section-sub">Loading…</p>
    </div>
  );
}
