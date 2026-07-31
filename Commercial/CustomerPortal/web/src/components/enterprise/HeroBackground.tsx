"use client";

import { useEffect, useRef, useState } from "react";

export function HeroBackground() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [videoReady, setVideoReady] = useState(false);
  const [shouldLoadVideo, setShouldLoadVideo] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (mq.matches) return;
    const timer = window.setTimeout(() => setShouldLoadVideo(true), 40);
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
      {shouldLoadVideo && (
        <video
          ref={videoRef}
          className={`e-hero-video ${videoReady ? "e-hero-video--visible" : ""}`}
          muted
          loop
          playsInline
          autoPlay
          preload="auto"
          poster="/brand/the-gold-mind-square.png"
          onPlaying={() => setVideoReady(true)}
          onError={() => setVideoReady(false)}
        >
          <source src="/media/hero-institutional.mp4" type="video/mp4" />
          <source src="/media/hero-institutional.webm" type="video/webm" />
        </video>
      )}
      <div className="e-hero-overlay e-hero-overlay--video" />
      <div className="e-hero-glass e-hero-glass--light" />
    </div>
  );
}
