# CUSTOMER_FLOW_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Commit:** `225f8e5`

---

## Customer journey simulation

### 1. Website (public)

| Step | Route | Expected | Status |
|------|-------|----------|--------|
| Landing page | `/` | 200, enterprise UI | **PASS** (local build; prod blocked by Vercel SSO) |
| About / Company / Tech | `/about`, `/company`, `/technology` | 200 | **PASS** (local) |
| Pricing | `/pricing` | 200, plan cards | **PASS** (local) |
| Documentation | `/docs` | 200, sidebar + FAQ | **PASS** (local) |
| Contact | `/contact` | 200 | **PASS** (local) |
| Legal | `/privacy`, `/terms`, etc. | 200 | **PASS** (local) |

### 2. Sign in

| Step | Expected | Status |
|------|----------|--------|
| `/login` loads | 200, no redirect loop | **PASS** (verified `3cd9867`) |
| `/api/auth/providers` | 200 | **PASS** |
| Demo credentials login | Session created | **PASS** |
| Redirect to `/portal` | 200 | **PASS** |

### 3. Dashboard & portal workflows

| Step | Route | Status |
|------|-------|--------|
| Dashboard | `/portal` | **PASS** |
| Licenses | `/portal/licenses` | **PASS** |
| License create API | POST with Origin | **PASS** |
| Billing | `/portal/billing` | **PASS** (sandbox mode) |
| Downloads | `/portal/downloads` | **PASS** |
| Devices (MT5) | `/portal/devices` | **PASS** |
| Support | `/portal/support` | **PASS** |
| Account | `/portal/account` | **PASS** |

### 4. Installer & activation

| Step | Status | Notes |
|------|--------|-------|
| Download installer link | **PASS** (portal page) | Setup.exe binary Owner-hosted |
| Install | **PENDING** | Requires Setup.exe on machine |
| License activation | **PASS** (script + API) | Static validation |
| MT5 EA deploy | **PASS** (script) | `Deploy-EA-To-MT5.ps1` |

### 5. Updates & support

| Step | Status |
|------|--------|
| Release check API | **PASS** |
| Support ticket create | **PASS** |
| Health monitoring | **PASS** (`/api/health` green at `3cd9867`) |

### 6. Logout & re-login

| Step | Status |
|------|--------|
| Session sign-out | **PASS** |
| Re-login | **PASS** |

---

## Production blocker

End-to-end production customer flow was verified at commit `3cd9867`. Current commit `225f8e5` is deployed but **public access is blocked** by:

1. Broken Vercel production alias (`404`)
2. Vercel Deployment Protection SSO on team URLs

These prevent new customers from reaching the site without Owner Vercel configuration.

---

## Verdict

**Customer flow: PASS (application)** — all portal workflows operational with demo auth + sandbox billing. **Production access: OWNER ACTION REQUIRED** (Vercel configuration).
