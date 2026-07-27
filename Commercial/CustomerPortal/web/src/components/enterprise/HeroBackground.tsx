"use client";

import { useEffect, useRef, useState } from "react";
import { FinancialParticles } from "./FinancialParticles";

export function HeroBackground() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [videoReady, setVideoReady] = useState(false);
  const [shouldLoadVideo, setShouldLoadVideo] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (mq.matches) return;

    const timer = window.setTimeout(() => setShouldLoadVideo(true), 120);
    return () => window.clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (!shouldLoadVideo || !videoRef.current) return;
    const v = videoRef.current;
    v.load();
    const play = () => v.play().catch(() => undefined);
    if (v.readyState >= 2) play();
    else v.addEventListener("canplay", play, { once: true });
  }, [shouldLoadVideo]);

  return (
    <div className="e-hero-bg" aria-hidden="true">
      <div className="e-hero-cinematic-base" />
      <FinancialParticles density={56} />
      {shouldLoadVideo && (
        <video
          ref={videoRef}
          className={`e-hero-video ${videoReady ? "e-hero-video--visible" : ""}`}
          muted
          loop
          playsInline
          preload="none"
          poster="/brand/the-gold-mind-og-1200x630.png"
          onPlaying={() => setVideoReady(true)}
          onError={() => setVideoReady(false)}
        >
          <source src="/media/hero-institutional.webm" type="video/webm" />
          <source src="/media/hero-institutional.mp4" type="video/mp4" />
        </video>
      )}
      <div className="e-hero-overlay" />
      <div className="e-hero-glass" />
      <div className="e-hero-mesh" />
    </div>
  );
}
