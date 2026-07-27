"use client";

export function HeroBackground() {
  return (
    <div className="e-hero-bg" aria-hidden="true">
      <video
        className="e-hero-video"
        autoPlay
        muted
        loop
        playsInline
        preload="metadata"
        poster="/brand/the-gold-mind-og-1200x630.png"
      >
        <source src="/media/hero-institutional.mp4" type="video/mp4" />
      </video>
      <div
        className="e-hero-video-fallback"
        style={{
          position: "absolute",
          inset: 0,
          background:
            "linear-gradient(135deg, #0a0a0a 0%, #111 40%, #0d0d0d 100%), radial-gradient(ellipse at 60% 40%, rgba(184,155,95,0.08), transparent 60%)",
        }}
      />
      <div className="e-hero-overlay" />
      <div className="e-hero-mesh" />
    </div>
  );
}
