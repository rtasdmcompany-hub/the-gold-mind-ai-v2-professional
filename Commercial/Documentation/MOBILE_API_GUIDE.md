# MOBILE_API_GUIDE.md

Base path: `/api/mobile`

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/mobile/auth` | Email / Google / 2FA / refresh / logout |
| GET | `/api/mobile/dashboard` | Customer dashboard snapshot |
| GET/POST | `/api/mobile/licenses` | License list / activate / transfer |
| GET | `/api/mobile/devices` | Mobile + license devices |
| GET/POST | `/api/mobile/notifications` | Inbox · preferences |
| GET/POST | `/api/mobile/support` | KB · tickets · diagnostics |
| GET | `/api/mobile/health` | Companion health (no trading) |
| GET | `/api/admin/mobile` | Admin mobile ops dashboard |

Auth header: `Authorization: Bearer <accessToken>`

All routes are commercial-only and gateway-wrapped.
