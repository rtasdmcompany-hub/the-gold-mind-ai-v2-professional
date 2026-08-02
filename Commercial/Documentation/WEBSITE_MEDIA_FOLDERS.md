# Website media — where to change videos & images

All public website assets for THE GOLD MIND Customer Portal / marketing site live under:

`Commercial/CustomerPortal/web/public/`

## Phone panel rotating ads (homepage iPhone)

**Folder:** `public/media/phone-ads/`  
**Config:** `public/media/phone-ads/ads.json`  
**Component:** `src/components/enterprise/HeroDashboard.tsx`

Each ad can have its own video, poster, short details line, and clickable link.

### Current MQL5 Market ad

- Video: `public/media/phone-ads/mql5-market.mp4`
- Poster: `public/media/phone-ads/mql5-market-poster.jpg`
- Click opens: [MQL5 Market product 183685](https://www.mql5.com/en/market/product/183685?source=Site+Market+MT5+Search+Rating007%3athe+gold+mind)

### Add another rotating ad

1. Copy `your-ad.mp4` + `your-ad-poster.jpg` into `public/media/phone-ads/`
2. Append to `ads.json`:

```json
{
  "id": "your-ad",
  "enabled": true,
  "title": "Campaign title",
  "details": "Short line on the phone (or \"\")",
  "href": "https://your-landing-page.example",
  "video": "/media/phone-ads/your-ad.mp4",
  "poster": "/media/phone-ads/your-ad-poster.jpg"
}
```

3. Commit, push, redeploy Vercel.

Enabled ads play in list order; when a video ends, the next one starts. Set `"enabled": false` to skip an ad without deleting it. Leave `"details": ""` to hide the bottom line.

See also: `public/media/phone-ads/README.md`

## Other videos

| File | Used for | Path |
|------|----------|------|
| `hero-institutional.mp4` | Full-bleed hero background (desktop) | `public/media/hero-institutional.mp4` |
| `hero-institutional.webm` | Hero background (WebM fallback) | `public/media/hero-institutional.webm` |
| `live-ad-portrait.mp4` | Legacy copy (kept for reference) | `public/media/live-ad-portrait.mp4` |

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
