# PORTAL_STRUCTURE.md

**Phase:** 9 · Sprint 2  
**App root:** `Commercial/CustomerPortal/web`

---

## Directory map

```
web/
├── src/
│   ├── auth.ts                 # NextAuth config (Google + Demo)
│   ├── middleware.ts           # Protected routes
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx            # → /portal
│   │   ├── globals.css         # Black & Gold tokens
│   │   ├── login/page.tsx
│   │   ├── api/auth/[...nextauth]/route.ts
│   │   └── portal/
│   │       ├── layout.tsx
│   │       ├── page.tsx                # Dashboard
│   │       ├── licenses/
│   │       ├── downloads/
│   │       ├── subscriptions/
│   │       ├── devices/
│   │       ├── invoices/
│   │       ├── orders/
│   │       ├── support/
│   │       ├── knowledge-base/
│   │       ├── announcements/
│   │       ├── account/
│   │       └── security/
│   ├── components/
│   │   ├── PortalNav.tsx
│   │   ├── SignOutButton.tsx
│   │   └── StatusBadge.tsx
│   ├── lib/
│   │   ├── mock-data.ts        # Read-only MVP data
│   │   ├── nav.ts
│   │   └── types.ts
│   └── types/next-auth.d.ts
├── .env.local.example
├── package.json
└── README.md
```

---

## Data layer (Sprint 2)

Mock modules only — replace with Cloud License API in later queue steps **without** redesigning page IA.

---

## Separation guarantee

This tree lives under `/Commercial/CustomerPortal` only. It must never be imported by MetaTrader Experts or Core Include trading modules.

---

*End of PORTAL_STRUCTURE.md*
