# PORTAL_SECURITY.md

**Phase:** 9 · Sprint 2  
**Service:** THE GOLD MIND Customer Portal (standalone)

---

## 1. Authentication

| Method | When |
|--------|------|
| Google OAuth | `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` set |
| Demo Credentials | `PORTAL_DEMO_AUTH=true` or Google missing (MVP/local) |

Library: **NextAuth / Auth.js v5**.

---

## 2. Session management

- Strategy: JWT  
- Max age: 8 hours  
- Cookie session via Auth.js defaults  
- `trustHost: true` for deployment flexibility  

---

## 3. Protected routes

`src/middleware.ts` wraps App Router:

- Unauthenticated users → `/login?callbackUrl=…`  
- Authenticated on `/login` → `/portal`  
- Public: `/login`, `/api/auth/*`  

---

## 4. Role-based access foundation

- JWT / session field: `role` (`customer` default)  
- Admin routes not exposed yet — reserved for later  

---

## 5. Secure logout

Server action calls `signOut({ redirectTo: "/login" })`.

---

## 6. Isolation from Core

- No MQ5 / Experts / Include Trading paths imported  
- No order, risk, or recovery APIs  
- Portal cannot affect live trading behaviour  

---

## 7. Secrets

Never commit real Google secrets. Use `.env.local` (gitignored). Rotate `NEXTAUTH_SECRET` in production.

---

*End of PORTAL_SECURITY.md*
