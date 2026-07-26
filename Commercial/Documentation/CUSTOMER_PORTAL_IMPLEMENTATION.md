# CUSTOMER_PORTAL_IMPLEMENTATION.md

**Phase:** 9 · Sprint 2  
**Location:** `Commercial/CustomerPortal/web`  
**Stack:** Next.js 15 · React 19 · NextAuth (Auth.js) · CSS design tokens  
**Isolation:** Standalone commercial service — **zero** Core Trading Engine / MQ5 imports

---

## 1. What shipped (MVP)

| Area | Status |
|------|--------|
| Portal sections (12) | Implemented with routes |
| Dashboard metrics | Mock + session name/email |
| Licenses | Read-only list/details fields |
| Downloads | Versions, checksum, requirements, history |
| Devices | Table + disabled future actions |
| Google OAuth | Integrated (env-gated) |
| Demo Sign-In | Enabled for local/MVP validation |
| Protected routes | Middleware on `/portal/*` |
| RBAC foundation | JWT `role` (customer / admin reserved) |
| Secure logout | Server action sign-out |
| Black & Gold UI | Design system tokens |
| Responsive | Desktop / laptop / tablet / mobile nav collapse |

---

## 2. Run locally

```bash
cd Commercial/CustomerPortal/web
cp .env.local.example .env.local   # if needed
npm install
npm run dev
```

Open `http://localhost:3000` → redirects to `/portal` (auth) → `/login`.

---

## 3. Environment

| Variable | Purpose |
|----------|---------|
| `NEXTAUTH_URL` | App origin |
| `NEXTAUTH_SECRET` | Session encryption |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth |
| `PORTAL_DEMO_AUTH` | Allow Demo Sign-In |

---

## 4. Explicitly not in Sprint 2

- License generation / payment webhooks  
- Live activate/deactivate devices  
- Live ticket backend  
- Connection to MetaTrader / Core  

---

## 5. Board Condition impact

Advances **BC-PORTAL** toward IN PROGRESS / partial VERIFIED (MVP shell). Full VERIFIED still needs live license/download wiring (later queue steps).

---

*End of CUSTOMER_PORTAL_IMPLEMENTATION.md*
