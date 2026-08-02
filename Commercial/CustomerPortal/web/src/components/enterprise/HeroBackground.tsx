"use client";

import { useEffect, useRef, useState } from "react";
import { useSiteContent } from "./SiteContentProvider";

export function HeroBackground() {
  const { hero } = useSiteContent();
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
    setVideoReady(false);
    if (!shouldLoadVideo || !videoRef.current) return;
    const v = videoRef.current;
    v.load();
    const play = () => v.play().catch(() => undefined);
    if (v.readyState >= 2) play();
    else v.addEventListener("canplay", play, { once: true });
  }, [shouldLoadVideo, hero.backgroundMp4, hero.backgroundWebm]);

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
          poster={hero.poster || "/brand/the-gold-mind-square.png"}
          onPlaying={() => setVideoReady(true)}
          onError={() => setVideoReady(false)}
        >
          {hero.backgroundMp4 ? <source src={hero.backgroundMp4} type="video/mp4" /> : null}
          {hero.backgroundWebm ? <source src={hero.backgroundWebm} type="video/webm" /> : null}
        </video>
      )}
      <div className="e-hero-overlay e-hero-overlay--video" />
      <div className="e-hero-glass e-hero-glass--light" />
    </div>
  );
}
