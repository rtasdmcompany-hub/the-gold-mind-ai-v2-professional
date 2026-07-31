"""Generate a cinematic looping trading chart hero video (1920x1080)."""
from __future__ import annotations

import math
import os
import random
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

W, H = 1920, 1080
FPS = 24
SECONDS = 8
N_FRAMES = FPS * SECONDS
CANDLES = 48
GOLD = (184, 155, 95)
GOLD_SOFT = (212, 190, 130)
BG = (6, 6, 8)
GRID = (28, 28, 32)
UP = (72, 168, 118)
DOWN = (196, 78, 78)

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "public" / "media"
FRAMES = OUT_DIR / "_hero_frames"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def gen_series(seed: int = 42) -> list[tuple[float, float, float, float]]:
    rng = random.Random(seed)
    price = 2340.0
    out = []
    for i in range(CANDLES + 40):
        drift = math.sin(i / 7.5) * 1.8 + math.cos(i / 13.0) * 1.1
        open_p = price
        close_p = price + drift + rng.uniform(-2.4, 2.8)
        high = max(open_p, close_p) + rng.uniform(0.4, 3.2)
        low = min(open_p, close_p) - rng.uniform(0.4, 3.2)
        out.append((open_p, high, low, close_p))
        price = close_p
    return out


SERIES = gen_series()


def draw_frame(t: float) -> Image.Image:
    """t in [0, 1) loop progress."""
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # vignette-ish radial fill
    for r in range(0, 900, 40):
        alpha = int(18 * (1 - r / 900))
        if alpha <= 0:
            break
        color = (12 + alpha // 2, 11 + alpha // 3, 8 + alpha // 4)
        draw.ellipse([W // 2 - r * 1.4, H // 2 - r, W // 2 + r * 1.4, H // 2 + r], outline=color)

    # chart panel
    left, top, right, bottom = 120, 140, W - 120, H - 160
    draw.rounded_rectangle([left - 8, top - 8, right + 8, bottom + 8], radius=18, outline=(40, 36, 28), width=1)
    draw.rectangle([left, top, right, bottom], fill=(9, 9, 11))

    # grid
    for i in range(1, 8):
        y = top + (bottom - top) * i / 8
        draw.line([(left, y), (right, y)], fill=GRID, width=1)
    for i in range(1, 12):
        x = left + (right - left) * i / 12
        draw.line([(x, top), (x, bottom)], fill=GRID, width=1)

    # scrolling window of candles
    offset = int(t * 24) % 24
    window = SERIES[offset : offset + CANDLES]
    prices = [p for c in window for p in c]
    lo, hi = min(prices), max(prices)
    pad = (hi - lo) * 0.12 or 1
    lo -= pad
    hi += pad

    def y_of(p: float) -> float:
        return bottom - (p - lo) / (hi - lo) * (bottom - top)

    cw = (right - left) / CANDLES
    body_w = max(4, cw * 0.55)

    # gold EMA-like curve
    closes = [c[3] for c in window]
    points = []
    for i, c in enumerate(closes):
        x = left + cw * (i + 0.5)
        points.append((x, y_of(c)))
    if len(points) >= 2:
        draw.line(points, fill=GOLD_SOFT + (0,), width=3)

    for i, (o, h, l, c) in enumerate(window):
        x = left + cw * (i + 0.5)
        color = UP if c >= o else DOWN
        draw.line([(x, y_of(h)), (x, y_of(l))], fill=color, width=2)
        y1, y2 = y_of(o), y_of(c)
        top_b, bot_b = min(y1, y2), max(y1, y2)
        if abs(bot_b - top_b) < 2:
            bot_b = top_b + 2
        draw.rectangle([x - body_w / 2, top_b, x + body_w / 2, bot_b], fill=color)

    # HUD labels
    draw.text((left + 18, top + 14), "XAUUSD  ·  H1  ·  LIVE MARKET FEED", fill=GOLD)
    draw.text((right - 260, top + 14), "THE GOLD MIND AI v2.0", fill=GOLD_SOFT)
    mid = window[len(window) // 2][3]
    draw.text((left + 18, bottom + 24), f"SPOT  {mid:.2f}", fill=(200, 200, 200))
    draw.text((left + 220, bottom + 24), "SPREAD  0.18", fill=(140, 140, 140))
    draw.text((left + 420, bottom + 24), "VOL  INSTITUTIONAL", fill=(140, 140, 140))

    # subtle scanline / light sweep
    sweep_x = left + (right - left) * ((t * 1.35) % 1.0)
    for dx in range(-40, 41, 4):
        a = max(0, 28 - abs(dx))
        if a:
            draw.line([(sweep_x + dx, top), (sweep_x + dx, bottom)], fill=(184, 155, 95), width=1)

    # soft glow pass
    glow = img.filter(ImageFilter.GaussianBlur(radius=1.2))
    return Image.blend(img, glow, 0.18)


def main() -> int:
    if FRAMES.exists():
        shutil.rmtree(FRAMES)
    FRAMES.mkdir(parents=True)

    print(f"Rendering {N_FRAMES} frames…", flush=True)
    for i in range(N_FRAMES):
        t = i / N_FRAMES
        frame = draw_frame(t)
        frame.save(FRAMES / f"frame_{i:04d}.png", optimize=True)
        if i % 24 == 0:
            print(f"  frame {i}/{N_FRAMES}", flush=True)

    ffmpeg = shutil.which("ffmpeg") or r"C:\Users\Dell\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
    mp4 = OUT_DIR / "hero-institutional.mp4"
    webm = OUT_DIR / "hero-institutional.webm"
    pattern = str(FRAMES / "frame_%04d.png")

    cmd_mp4 = [
        ffmpeg, "-y", "-framerate", str(FPS), "-i", pattern,
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23",
        "-movflags", "+faststart", "-an", str(mp4),
    ]
    cmd_webm = [
        ffmpeg, "-y", "-framerate", str(FPS), "-i", pattern,
        "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "32", "-an", str(webm),
    ]
    print("Encoding MP4…", flush=True)
    subprocess.check_call(cmd_mp4)
    print("Encoding WebM…", flush=True)
    subprocess.check_call(cmd_webm)
    shutil.rmtree(FRAMES, ignore_errors=True)
    print(f"Done: {mp4} ({mp4.stat().st_size} bytes)")
    print(f"Done: {webm} ({webm.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
