"use client";

import { useEffect, useRef, useState } from "react";
import { brand } from "@/lib/brand";

/**
 * Homepage right-side 16:9 panel with product video ad.
 * Replace: public/media/live-ad-16x9.mp4 (+ live-ad-16x9-poster.jpg).
 */
export function HeroDashboard() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [ready, setReady] = useState(false);
  const [loadVideo, setLoadVideo] = useState(false);
  const [muted, setMuted] = useState(true);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (mq.matches) return;
    const t = window.setTimeout(() => setLoadVideo(true), 60);
    return () => window.clearTimeout(t);
  }, []);

  useEffect(() => {
    if (!loadVideo || !videoRef.current) return;
    const v = videoRef.current;
    v.muted = true;
    v.load();
    const play = () => v.play().catch(() => undefined);
    if (v.readyState >= 2) play();
    else v.addEventListener("canplay", play, { once: true });
  }, [loadVideo]);

  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;
    v.muted = muted;
    if (!muted) {
      v.volume = 1;
      void v.play().catch(() => undefined);
    }
  }, [muted]);

  function toggleMute() {
    setMuted((m) => !m);
  }

  return (
    <div className="e-dashboard e-dashboard--portrait" aria-label={`${brand.brandName} product preview`}>
      <div className="e-dashboard-header">
        <span className="e-dashboard-title">{brand.brandName}</span>
      </div>

      <div className="e-dashboard-video-frame">
        {loadVideo ? (
          <video
            ref={videoRef}
            className={`e-dashboard-video ${ready ? "e-dashboard-video--ready" : ""}`}
            muted={muted}
            loop
            playsInline
            autoPlay
            preload="auto"
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

        <button
          type="button"
          className="e-dashboard-mute-btn"
          onClick={toggleMute}
          aria-pressed={!muted}
          aria-label={muted ? "Unmute video" : "Mute video"}
        >
          {muted ? "Unmute" : "Mute"}
        </button>

        <div className="e-dashboard-video-caption">
          <span>Product ad</span>
          <span>{brand.productName}</span>
        </div>
      </div>
    </div>
  );
}
