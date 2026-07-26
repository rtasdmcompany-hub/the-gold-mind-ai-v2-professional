import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "THE GOLD MIND · Customer Portal",
  description:
    "THE GOLD MIND PROFESSIONAL Customer Portal — licenses, downloads, devices, and support. Standalone commercial service.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
