"use client";

import { useEffect, useRef } from "react";

/** Lightweight cinematic candlestick overlay for the landing hero. */
export function TradingChartOverlay() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (mq.matches) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let raf = 0;
    let running = true;
    const candles: { o: number; h: number; l: number; c: number }[] = [];
    let price = 0.55;

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const { clientWidth: w, clientHeight: h } = canvas;
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    resize();
    window.addEventListener("resize", resize);

    for (let i = 0; i < 42; i++) {
      const o = price;
      const c = Math.min(0.92, Math.max(0.08, o + (Math.random() - 0.48) * 0.06));
      const h = Math.max(o, c) + Math.random() * 0.03;
      const l = Math.min(o, c) - Math.random() * 0.03;
      candles.push({ o, h, l, c });
      price = c;
    }

    let t = 0;
    const draw = () => {
      if (!running) return;
      t += 1;
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      ctx.clearRect(0, 0, w, h);

      // dark panel
      const padX = w * 0.08;
      const padY = h * 0.18;
      const cw = (w - padX * 2) / candles.length;

      ctx.strokeStyle = "rgba(184,155,95,0.18)";
      ctx.lineWidth = 1;
      ctx.strokeRect(padX - 8, padY - 8, w - padX * 2 + 16, h - padY * 2 + 16);

      for (let g = 0; g < 6; g++) {
        const y = padY + ((h - padY * 2) * g) / 5;
        ctx.beginPath();
        ctx.moveTo(padX, y);
        ctx.lineTo(w - padX, y);
        ctx.strokeStyle = "rgba(255,255,255,0.04)";
        ctx.stroke();
      }

      // advance market every ~18 frames
      if (t % 18 === 0) {
        const last = candles[candles.length - 1];
        const o = last.c;
        const c = Math.min(0.92, Math.max(0.08, o + (Math.random() - 0.47) * 0.05));
        candles.shift();
        candles.push({
          o,
          h: Math.max(o, c) + Math.random() * 0.025,
          l: Math.min(o, c) - Math.random() * 0.025,
          c,
        });
      }

      candles.forEach((k, i) => {
        const x = padX + cw * (i + 0.5);
        const yO = padY + (1 - k.o) * (h - padY * 2);
        const yC = padY + (1 - k.c) * (h - padY * 2);
        const yH = padY + (1 - k.h) * (h - padY * 2);
        const yL = padY + (1 - k.l) * (h - padY * 2);
        const up = k.c >= k.o;
        const color = up ? "rgba(72,168,118,0.85)" : "rgba(196,78,78,0.85)";
        ctx.strokeStyle = color;
        ctx.beginPath();
        ctx.moveTo(x, yH);
        ctx.lineTo(x, yL);
        ctx.stroke();
        const top = Math.min(yO, yC);
        const bot = Math.max(yO, yC);
        ctx.fillStyle = color;
        ctx.fillRect(x - cw * 0.28, top, cw * 0.56, Math.max(2, bot - top));
      });

      // gold EMA
      ctx.beginPath();
      candles.forEach((k, i) => {
        const x = padX + cw * (i + 0.5);
        const y = padY + (1 - k.c) * (h - padY * 2);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      });
      ctx.strokeStyle = "rgba(232,213,163,0.55)";
      ctx.lineWidth = 2;
      ctx.stroke();

      // sweep
      const sx = padX + ((t * 3) % (w - padX * 2));
      const grad = ctx.createLinearGradient(sx - 40, 0, sx + 40, 0);
      grad.addColorStop(0, "rgba(184,155,95,0)");
      grad.addColorStop(0.5, "rgba(184,155,95,0.12)");
      grad.addColorStop(1, "rgba(184,155,95,0)");
      ctx.fillStyle = grad;
      ctx.fillRect(sx - 40, padY, 80, h - padY * 2);

      ctx.fillStyle = "rgba(184,155,95,0.75)";
      ctx.font = "12px Georgia, serif";
      ctx.fillText("XAUUSD  ·  INSTITUTIONAL FEED", padX, padY - 18);

      raf = requestAnimationFrame(draw);
    };
    raf = requestAnimationFrame(draw);

    return () => {
      running = false;
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
    };
  }, []);

  return <canvas ref={ref} className="e-hero-chart-overlay" aria-hidden="true" />;
}
