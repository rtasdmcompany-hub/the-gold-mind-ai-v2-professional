"use client";

import { useEffect, useRef, useState } from "react";
import { brand } from "@/lib/brand";

/**
 * Homepage right-side Live panel — portrait phone frame with product video ad.
 * Replace the ad file at: public/media/live-ad-portrait.mp4
 */
export function HeroDashboard() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [ready, setReady] = useState(false);
  const [loadVideo, setLoadVideo] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (mq.matches) return;
    const t = window.setTimeout(() => setLoadVideo(true), 60);
    return () => window.clearTimeout(t);
  }, []);

  useEffect(() => {
    if (!loadVideo || !videoRef.current) return;
    const v = videoRef.current;
    v.load();
    const play = () => v.play().catch(() => undefined);
    if (v.readyState >= 2) play();
    else v.addEventListener("canplay", play, { once: true });
  }, [loadVideo]);

  return (
    <div className="e-dashboard e-dashboard--portrait" aria-label={`${brand.brandName} live preview`}>
      <div className="e-dashboard-header">
        <span className="e-dashboard-title">{brand.brandName} · Live</span>
        <span className="e-dashboard-live-dot" aria-hidden="true" />
      </div>

      <div className="e-dashboard-video-frame">
        {loadVideo ? (
          <video
            ref={videoRef}
            className={`e-dashboard-video ${ready ? "e-dashboard-video--ready" : ""}`}
            muted
            loop
            playsInline
            autoPlay
            preload="metadata"
            poster="/media/live-ad-portrait-poster.jpg"
            onPlaying={() => setReady(true)}
            onError={() => setReady(false)}
          >
            <source src="/media/live-ad-portrait.mp4" type="video/mp4" />
          </video>
        ) : (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            className="e-dashboard-video e-dashboard-video--ready"
            src="/media/live-ad-portrait-poster.jpg"
            alt=""
          />
        )}
        <div className="e-dashboard-video-caption">
          <span>Product ad</span>
          <span>{brand.productName}</span>
        </div>
      </div>
    </div>
  );
}
