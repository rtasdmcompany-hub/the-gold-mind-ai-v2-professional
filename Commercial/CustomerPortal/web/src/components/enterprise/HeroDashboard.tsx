"use client";

import { useEffect, useRef, useState } from "react";
import { brand } from "@/lib/brand";

function SpeakerIcon({ muted }: { muted: boolean }) {
  if (muted) {
    return (
      <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true" focusable="false">
        <path
          fill="currentColor"
          d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3 3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4 9.91 6.09 12 8.18V4z"
        />
      </svg>
    );
  }
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true" focusable="false">
      <path
        fill="currentColor"
        d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"
      />
    </svg>
  );
}

/**
 * Homepage right-side portrait panel with product video ad.
 * Styled as an iPhone display. Replace: public/media/live-ad-portrait.mp4 (+ poster JPG).
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

  return (
    <div
      className="e-dashboard e-dashboard--portrait e-phone"
      aria-label={`${brand.brandName} product preview`}
    >
      <div className="e-phone-bezel" aria-hidden="true">
        <span className="e-phone-island" />
        <span className="e-phone-btn e-phone-btn--silent" />
        <span className="e-phone-btn e-phone-btn--vol-up" />
        <span className="e-phone-btn e-phone-btn--vol-down" />
        <span className="e-phone-btn e-phone-btn--power" />
      </div>

      <div className="e-dashboard-video-frame e-phone-screen">
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
          className={`e-dashboard-mute-btn e-dashboard-mute-btn--icon${muted ? " is-muted" : ""}`}
          onClick={() => setMuted((m) => !m)}
          aria-pressed={!muted}
          aria-label={muted ? "Unmute video" : "Mute video"}
          title={muted ? "Unmute" : "Mute"}
        >
          <SpeakerIcon muted={muted} />
        </button>
      </div>
    </div>
  );
}
