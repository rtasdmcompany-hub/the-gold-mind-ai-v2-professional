# Website media — where to change videos & images

All public website assets for THE GOLD MIND Customer Portal / marketing site live under:

`Commercial/CustomerPortal/web/public/`

## Videos

| File | Used for | Path |
|------|----------|------|
| `live-ad-portrait.mp4` | Homepage right portrait panel ad (with audio; UI starts muted) | `public/media/live-ad-portrait.mp4` |
| `live-ad-portrait-poster.jpg` | Poster / reduced-motion fallback for Live panel | `public/media/live-ad-portrait-poster.jpg` |
| `hero-institutional.mp4` | Full-bleed hero background (desktop) | `public/media/hero-institutional.mp4` |
| `hero-institutional.webm` | Hero background (WebM fallback) | `public/media/hero-institutional.webm` |

**To replace the Live panel ad:** overwrite  
`Commercial/CustomerPortal/web/public/media/live-ad-portrait.mp4`  
(prefer portrait ~9:16, H.264, under ~3–5 MB). Also refresh the poster JPG if the first frame changes.

Component: `src/components/enterprise/HeroDashboard.tsx`  
Hero background video: `src/components/enterprise/HeroBackground.tsx`

## Brand images / logos

Folder: `Commercial/CustomerPortal/web/public/brand/`

Examples:
- Nav / header logos: `the-gold-mind-logo-nav.png`, `the-gold-mind-logo-header.png`
- Square / OG / Twitter: `the-gold-mind-square.png`, `the-gold-mind-og-1200x630.png`, `the-gold-mind-twitter-1200x600.png`
- Icons / favicon: `the-gold-mind-icon-*.png`, `favicon.ico`
- Footer badges: `footer-*.png`, `rtas-*.png`

## Installer / Windows assets (not the website)

`Commercial/Installer/Professional/assets/brand/`

## After replacing files

1. Commit + push (or sync to GitHub).  
2. Redeploy Vercel production so `public/` assets go live.  
3. Hard-refresh the browser (Ctrl+F5) — videos/images are often cached.
