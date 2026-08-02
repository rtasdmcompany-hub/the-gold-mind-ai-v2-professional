# Phone panel rotating ads

Homepage iPhone video panel reads this folder.

## Add a new ad

1. Put files here, for example:
   - `my-campaign.mp4` (portrait ~9:16, H.264, keep under ~5 MB)
   - `my-campaign-poster.jpg` (first-frame / fallback image)
2. Edit `ads.json` and append an entry:

```json
{
  "id": "my-campaign",
  "enabled": true,
  "title": "Short title",
  "details": "One short line shown on the phone (optional)",
  "href": "https://example.com/landing",
  "video": "/media/phone-ads/my-campaign.mp4",
  "poster": "/media/phone-ads/my-campaign-poster.jpg"
}
```

3. Commit + push + redeploy Vercel.

## Fields

| Field | Required | Meaning |
|-------|----------|---------|
| `id` | yes | Unique key |
| `enabled` | yes | `false` skips this ad |
| `title` | yes | Accessibility / link label |
| `details` | no | Short line under the video (leave `""` to hide) |
| `href` | yes | Click opens this URL (new tab) |
| `video` | yes | Public path to mp4 |
| `poster` | yes | Public path to poster image |

## Rotation

When more than one enabled ad is listed, the panel plays them in order and advances when each video ends (`rotateOnEnd: true`).
