# THE GOLD MIND — 30s Cinematic Phone Ad (9:16)

**Format:** 9:16 vertical · ~30 seconds · cinematic commercial  
**Delivery target:** Homepage iPhone panel (`public/media/phone-ads/`)  
**Click-through:** https://www.mql5.com/en/market/product/183685?source=Site+Market+MT5+Search+Rating007%3athe+gold+mind  
**Talent:** American woman, ~22, smart office dress, professional trading floor / glass office  
**Tone:** Multinational, institutional, premium gold/black — never hype “guaranteed profit”

> This package is the **production brief + script + shot list**.  
> A photorealistic 4K human performance video must be produced in a video tool (Runway / Kling / Veo / HeyGen / traditional shoot) using this brief.

---

## 30-second script (spoken)

**[0–3s · HOOK]**  
“Most gold traders don’t fail because of the market…”

**[3–8s · TURN]**  
“…they fail because emotion takes over. I don’t. I run a system.”

**[8–16s · PRODUCT]**  
“This is THE GOLD MIND AI v2.0 Professional — institutional MetaTrader 5 automation with a certified Core, enterprise licensing, and controlled risk discipline.”

**[16–24s · PROOF / BENEFIT]**  
“Built for serious traders who want structure: clean execution logic, professional updates, and a secure Customer Portal for licenses and downloads.”

**[24–30s · CTA]**  
“Get THE GOLD MIND on MQL5 Market — tap now and start trading with a professional system.”  
*(on-screen: DOWNLOAD ON MQL5 MARKET)*

---

## Shot list (9:16)

| Time | Shot | Visual | Audio / VO |
|------|------|--------|------------|
| 0–3s | A | Slow push-in on talent at glass trading desk; gold candlesticks bokeh | Hook line |
| 3–8s | B | Medium close-up, talent to camera; subtle chart motion behind | Turn line |
| 8–16s | C | Over-shoulder / phone UI insert of product + logo; screens reflect gold | Product line |
| 16–24s | D | Walk-and-talk past monitors; cutaways: portal UI, license key card, MT5 chart | Benefit line |
| 24–30s | E | Hero end-card: talent + product mark + CTA button “MQL5 MARKET” | CTA + soft whoosh |

**Camera:** 35–50mm equivalent, shallow DOF, gentle handheld or motorized push.  
**Grade:** deep blacks, warm gold highlights, soft bloom on screens.  
**Text safe area:** keep captions in lower 20%, avoid Dynamic Island / mute button zone on our phone panel.

---

## On-screen captions (burn-in or lower-thirds)

1. `EMOTION LOSES. SYSTEMS WIN.`  
2. `THE GOLD MIND AI v2.0 PROFESSIONAL`  
3. `CERTIFIED CORE · MT5 · ENTERPRISE PORTAL`  
4. `AVAILABLE ON MQL5 MARKET`  
5. End card disclaimer (small): `Trading involves substantial risk of loss.`

---

## Production prompt (for AI video tools)

Use in Runway / Kling / Veo / similar:

> Vertical 9:16 cinematic commercial, 30 seconds, photoreal 4K.  
> A 22-year-old American woman in smart office attire (cream blouse, tailored navy blazer) presents inside a premium dark trading office with large monitors showing gold candlestick charts and network graphics.  
> She speaks confidently to camera about institutional MetaTrader 5 automation software named THE GOLD MIND AI v2.0 Professional.  
> Luxury fintech look: black and gold color grade, shallow depth of field, slow camera push-ins, subtle lens flares from screens, multinational advertising quality.  
> No cartoon style, no neon cyberpunk, no exaggerated gestures. End on product CTA energy toward MQL5 Market.

---

## Homepage panel integration (after you have the MP4)

1. Export H.264 MP4, 9:16, ~1080×1920 or 2160×3840, ~30s, under ~8–12 MB if possible for web.  
2. Save poster JPG (first frame).  
3. Add to:

```
Commercial/CustomerPortal/web/public/media/phone-ads/
  goldmind-cinematic-30s.mp4
  goldmind-cinematic-30s-poster.jpg
```

4. Append in `ads.json`:

```json
{
  "id": "cinematic-30s",
  "enabled": true,
  "title": "THE GOLD MIND — Cinematic Ad",
  "details": "Watch · Available on MQL5 Market",
  "href": "https://www.mql5.com/en/market/product/183685?source=Site+Market+MT5+Search+Rating007%3athe+gold+mind",
  "video": "/media/phone-ads/goldmind-cinematic-30s.mp4",
  "poster": "/media/phone-ads/goldmind-cinematic-30s-poster.jpg"
}
```

5. Commit, push, redeploy Vercel.

---

## Storyboard stills (generated references)

Saved under Cursor artifacts / can be copied into brand review packs:

- Hero / office presence  
- Talking-to-camera close-up  
- Product / phone UI moment  

These are **reference frames**, not the final motion ad.
