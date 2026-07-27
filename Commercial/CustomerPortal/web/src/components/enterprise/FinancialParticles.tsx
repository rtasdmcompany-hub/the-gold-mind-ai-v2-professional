"use client";

import { useEffect, useRef } from "react";

/**
 * Subtle institutional particle field — login + hero ambient layer.
 */
export function FinancialParticles({ density = 48 }: { density?: number }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let raf = 0;
    let w = 0;
    let h = 0;

    const particles = Array.from({ length: density }, () => ({
      x: Math.random(),
      y: Math.random(),
      r: 0.4 + Math.random() * 1.2,
      a: 0.08 + Math.random() * 0.22,
      vx: (Math.random() - 0.5) * 0.00015,
      vy: -0.00008 - Math.random() * 0.00012,
    }));

    const resize = () => {
      w = canvas.clientWidth;
      h = canvas.clientHeight;
      canvas.width = w;
      canvas.height = h;
    };

    const draw = () => {
      ctx.clearRect(0, 0, w, h);
      for (const p of particles) {
        p.x += p.vx;
        p.y += p.vy;
        if (p.y < 0) p.y = 1;
        if (p.x < 0 || p.x > 1) p.vx *= -1;

        const x = p.x * w;
        const y = p.y * h;
        const grad = ctx.createRadialGradient(x, y, 0, x, y, p.r * 3);
        grad.addColorStop(0, `rgba(212, 188, 130, ${p.a})`);
        grad.addColorStop(1, "rgba(212, 188, 130, 0)");
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(x, y, p.r * 3, 0, Math.PI * 2);
        ctx.fill();
      }
      raf = requestAnimationFrame(draw);
    };

    resize();
    window.addEventListener("resize", resize);
    raf = requestAnimationFrame(draw);

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
    };
  }, [density]);

  return <canvas ref={canvasRef} className="e-particles" aria-hidden="true" />;
}
