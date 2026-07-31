import Image from "next/image";
import Link from "next/link";
import { brand } from "@/lib/brand";

type Variant = "header" | "nav" | "login" | "footer" | "hero";

const SRC: Record<Variant, { src: string; width: number; height: number; alt: string }> = {
  header: {
    src: "/brand/the-gold-mind-logo-header.png",
    width: 280,
    height: 80,
    alt: brand.productFullName,
  },
  nav: {
    src: "/brand/the-gold-mind-logo-nav.png",
    width: 180,
    height: 72,
    alt: `${brand.brandName}`,
  },
  login: {
    src: "/brand/the-gold-mind-logo-login.png",
    width: 120,
    height: 120,
    alt: `${brand.brandName} Automated Trading Software`,
  },
  footer: {
    src: "/brand/the-gold-mind-logo-footer.png",
    width: 160,
    height: 48,
    alt: `${brand.brandName}`,
  },
  hero: {
    src: "/brand/the-gold-mind-logo-dark.png",
    width: 420,
    height: 420,
    alt: `${brand.brandName} Automated Trading Software`,
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
      className={className ?? "e-brand-logo"}
      style={{ width: "auto", height: "auto", maxWidth: "100%", objectFit: "contain" }}
    />
  );
  if (!href) return img;
  return (
    <Link href={href} className="e-brand-link" style={{ display: "inline-flex", alignItems: "center", textDecoration: "none" }}>
      {img}
    </Link>
  );
}



export function UserAvatar({
  name,
  image,
  size = 40,
}: {
  name?: string | null;
  image?: string | null;
  size?: number;
}) {
  const initials =
    (name || "?")
      .split(/\s+/)
      .map((s) => s[0])
      .join("")
      .slice(0, 2)
      .toUpperCase();

  if (image) {
    return (
      <Image
        src={image}
        alt={name || "User"}
        width={size}
        height={size}
        className="e-user-avatar"
        style={{ width: size, height: size, borderRadius: "50%", objectFit: "cover" }}
        unoptimized
      />
    );
  }

  return (
    <span className="e-user-avatar e-user-avatar--fallback" style={{ width: size, height: size, fontSize: size * 0.38 }}>
      {initials}
    </span>
  );
}
