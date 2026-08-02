# Phone panel rotating ads

**Preferred:** edit ads in the portal admin — **`/portal/admin/site-content`** (Site Content Manager).  
Uploads and URLs saved there apply live (no redeploy) when Upstash is configured.

This folder is the **built-in fallback** if the CMS store is empty.

## Manual fallback (optional)

1. Put files here, for example:
   - `my-campaign.mp4` (portrait ~9:16, H.264, keep under ~5 MB)
   - `my-campaign-poster.jpg`
2. Edit `ads.json` and append an entry, then commit + redeploy — **or** paste the same paths/URLs into Site Content and Save.

See `Commercial/Documentation/SITE_CONTENT_CMS.md`.
