import { ScrollReveal } from "./ScrollReveal";

export function InnerPage({
  eyebrow,
  title,
  subtitle,
  children,
}: {
  eyebrow: string;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <>
      <div className="e-page-hero e-container">
        <ScrollReveal>
          <p className="e-eyebrow">{eyebrow}</p>
          <h1 className="e-section-title">{title}</h1>
          {subtitle && <p className="e-section-sub">{subtitle}</p>}
        </ScrollReveal>
      </div>
      <section className="e-section" style={{ paddingTop: 0 }}>
        <div className="e-container">{children}</div>
      </section>
    </>
  );
}
