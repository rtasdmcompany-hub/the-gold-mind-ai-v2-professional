import Image from "next/image";
import Link from "next/link";

type Variant = "header" | "nav" | "login" | "footer" | "hero";

const SRC: Record<Variant, { src: string; width: number; height: number; alt: string }> = {
  header: {
    src: "/brand/the-gold-mind-logo-header.png",
    width: 220,
    height: 64,
    alt: "THE GOLD MIND AI v2.0 PROFESSIONAL",
  },
  nav: {
    src: "/brand/the-gold-mind-logo-nav.png",
    width: 180,
    height: 72,
    alt: "THE GOLD MIND",
  },
  login: {
    src: "/brand/the-gold-mind-logo-login.png",
    width: 280,
    height: 280,
    alt: "THE GOLD MIND Automated Trading Software",
  },
  footer: {
    src: "/brand/the-gold-mind-logo-footer.png",
    width: 160,
    height: 48,
    alt: "THE GOLD MIND",
  },
  hero: {
    src: "/brand/the-gold-mind-logo-dark.png",
    width: 420,
    height: 420,
    alt: "THE GOLD MIND Automated Trading Software",
  },
};

export function BrandLogo({
  variant = "header",
  href,
  priority = false,
  className,
}: {
  variant?: Variant;
  href?: string;
  priority?: boolean;
  className?: string;
}) {
  const cfg = SRC[variant];
  const img = (
    <Image
      src={cfg.src}
      alt={cfg.alt}
      width={cfg.width}
      height={cfg.height}
      priority={priority}
      className={className}
      style={{ width: "auto", height: "auto", maxWidth: "100%", objectFit: "contain" }}
    />
  );
  if (!href) return img;
  return (
    <Link href={href} style={{ display: "inline-flex", alignItems: "center", textDecoration: "none" }}>
      {img}
    </Link>
  );
}

export function RtasGroupBadge({ height = 48 }: { height?: number }) {
  return (
    <Image
      src="/brand/rtas-group-footer-badge.png"
      alt="A Project Of RTAS GROUP OF COMPANIES"
      width={Math.round(height * 1.4)}
      height={height}
      style={{ width: "auto", height, objectFit: "contain" }}
    />
  );
}

export function RtasDigitalBadge({ height = 40 }: { height?: number }) {
  return (
    <Image
      src="/brand/rtas-digital-marketing-footer.png"
      alt="RTAS Digital Marketing Company"
      width={Math.round(height * 1.4)}
      height={height}
      style={{ width: "auto", height, objectFit: "contain" }}
    />
  );
}
