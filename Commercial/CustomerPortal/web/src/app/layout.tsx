import type { Metadata, Viewport } from "next";
import { Cormorant_Garamond, Inter } from "next/font/google";
import "./globals.css";
import "../styles/enterprise.css";

const serif = Cormorant_Garamond({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-serif",
  display: "swap",
});

const sans = Inter({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXTAUTH_URL || "https://the-gold-mind-ai-v2-professional.vercel.app"),
  title: {
    default: "THE GOLD MIND AI v2.0 PROFESSIONAL",
    template: "%s · THE GOLD MIND PROFESSIONAL",
  },
  description:
    "THE GOLD MIND AI v2.0 PROFESSIONAL by RTAS — Customer Portal, licensing, and certified Core. Trading involves risk of loss.",
  applicationName: "THE GOLD MIND AI v2.0 PROFESSIONAL",
  authors: [{ name: "RTAS GROUP OF COMPANIES" }],
  creator: "RTAS Digital Marketing Company",
  publisher: "RTAS GROUP OF COMPANIES",
  keywords: [
    "THE GOLD MIND",
    "MetaTrader 5",
    "Expert Advisor",
    "RTAS",
    "automated trading",
    "Customer Portal",
  ],
  manifest: "/site.webmanifest",
  icons: {
    icon: [
      { url: "/favicon.ico" },
      { url: "/brand/the-gold-mind-icon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/brand/the-gold-mind-icon-192.png", sizes: "192x192", type: "image/png" },
    ],
    apple: [{ url: "/brand/the-gold-mind-icon-180.png", sizes: "180x180", type: "image/png" }],
  },
  openGraph: {
    title: "THE GOLD MIND AI v2.0 PROFESSIONAL",
    description: "Official website and Customer Portal — licenses, downloads, and certified Core.",
    type: "website",
    siteName: "THE GOLD MIND AI v2.0 PROFESSIONAL",
    images: [
      {
        url: "/brand/the-gold-mind-og-1200x630.png",
        width: 1200,
        height: 630,
        alt: "THE GOLD MIND Automated Trading Software",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "THE GOLD MIND AI v2.0 PROFESSIONAL",
    description: "Official website and Customer Portal by RTAS.",
    images: ["/brand/the-gold-mind-twitter-1200x600.png"],
  },
};

export const viewport: Viewport = {
  themeColor: "#050505",
  colorScheme: "dark",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${serif.variable} ${sans.variable}`}>
      <body>{children}</body>
    </html>
  );
}
