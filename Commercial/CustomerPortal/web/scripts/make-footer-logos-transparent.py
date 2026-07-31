"""Corner flood-fill transparency + uniform square footer logos."""
from __future__ import annotations

from collections import deque
from pathlib import Path
from PIL import Image

BRAND = Path(r"H:\PERSONAL\RTAS Digital Marketing Company\RTAS Softwear\THE GOLD MIND AI v2.0 Professional\Commercial\CustomerPortal\web\public\brand")
SIZE = 256


def flood_clear(im: Image.Image, match: str, tol: int = 38) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()

    def is_bg(r: int, g: int, b: int, a: int) -> bool:
        if a < 8:
            return True
        if match == "black":
            return r <= tol and g <= tol and b <= tol
        # white / light gray canvas
        return r >= 255 - tol and g >= 255 - tol and b >= 255 - tol

    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (0, h // 2)):
        q.append((x, y))

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
            continue
        visited[y][x] = True
        r, g, b, a = px[x, y]
        if not is_bg(r, g, b, a):
            continue
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    # soften leftover near-bg fringe
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a and is_bg(r, g, b, a):
                # only clear if mostly surrounded by transparent
                neigh = 0
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] < 8:
                        neigh += 1
                if neigh >= 2:
                    px[x, y] = (0, 0, 0, 0)
    return im


def fit_square(im: Image.Image, size: int = SIZE) -> Image.Image:
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    im.thumbnail((size - 8, size - 8), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(im, ((size - im.width) // 2, (size - im.height) // 2), im)
    return canvas


def main() -> None:
    jobs = [
        ("the-gold-mind-square.png", "black", "footer-gold-mind.png", 42),
        ("rtas-group-hex.png", "black", "footer-rtas-group.png", 42),
        ("rtas-digital-hex.png", "white", "footer-rtas-digital.png", 36),
    ]
    for src_name, mode, out_name, tol in jobs:
        src = BRAND / src_name
        out = BRAND / out_name
        im = Image.open(src)
        cleared = flood_clear(im, mode, tol)
        # digital logo may sit on black after prior edits — also try black if white did little
        if mode == "white":
            sample = cleared.getpixel((2, 2))
            if sample[3] > 200 and sample[0] < 40:
                cleared = flood_clear(Image.open(src), "black", 42)
        fit_square(cleared).save(out, "PNG")
        print(f"OK {out_name}")


if __name__ == "__main__":
    main()
