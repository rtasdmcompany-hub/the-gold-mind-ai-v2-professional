# BRAND_STANDARD.md

**Product:** THE GOLD MIND · Automated Trading Software  
**Commercial identity:** THE GOLD MIND only (separate commercial product)  
**Updated:** 2026-07-31  

---

## 1. Official identity (textual — mandatory)

Use exactly:

- **THE GOLD MIND**
- **THE GOLD MIND PROFESSIONAL**
- **Automated Trading Software**

Product edition lockups:

- **THE GOLD MIND PROFESSIONAL** (Website)
- **THE GOLD MIND MARKET** (MQL5 Market)

Do **not** use RTAS Studio, RTAS Group, RTAS Digital, or other company-group branding in any customer-facing surface.

Do **not** redesign logos.  
Place official binary assets under `Commercial/Assets/` only as supplied for THE GOLD MIND.

---

## 2. Email identity (placeholders until domain cutover)

| Role | Address |
|------|---------|
| Support | support@thegoldmind.ai |
| Admin | admin@thegoldmind.ai |
| Billing | billing@thegoldmind.ai |
| License | license@thegoldmind.ai |
| Transactional From | THE GOLD MIND PROFESSIONAL \<noreply@thegoldmind.ai\> |

Canonical constants: `Commercial/CustomerPortal/web/src/lib/brand.ts`

Shared infrastructure accounts (Resend, Google Cloud, Paddle, Upstash) are allowed. Customer-visible From/Reply-To/support addresses must use THE GOLD MIND identity only.

---

## 3. Primary theme — Premium Black · Luxury Gold · Modern Enterprise

### Color tokens (commercial UI / web guidance)

| Token | Role | Hex (guidance) |
|-------|------|----------------|
| `--gm-black-950` | Primary background | `#0B0B0C` |
| `--gm-black-900` | Surface / panels | `#141416` |
| `--gm-black-800` | Elevated surface | `#1C1C1F` |
| `--gm-gold-500` | Primary luxury accent | `#C6A75E` |
| `--gm-gold-300` | Highlight / hover gold | `#E1C57A` |
| `--gm-ivory-100` | Primary text on black | `#F3EFE6` |
| `--gm-ivory-300` | Secondary text | `#C9C2B4` |
| `--gm-danger` | Critical alerts only | `#B33A3A` |
| `--gm-success` | Healthy / ready | `#2F6B4F` |

**Avoid:** generic purple “AI” gradients, neon crypto aesthetics, cluttered multi-accent rainbows.

### Typography guidance

| Use | Guidance |
|-----|----------|
| Brand moments | Refined serif or premium display (as per official brand kit when supplied) |
| Product UI | Clean modern sans for dense trading UI readability |
| Code/logs | Monospace (developer surfaces only) |

### Visual style

- Modern Enterprise  
- High contrast gold-on-black for CTAs and brand marks  
- Generous calm spacing on commercial screens; denser only in pro trader data views  
- Motion: rare, purposeful status fades — never decorative noise  

---

## 4. Voice & tone

| Do | Don’t |
|----|-------|
| Precise, calm, premium | Hype, “guaranteed profits” |
| “Frozen Core · sole execution authority” | “AI controls everything” |
| Clear risk disclosure | Hidden risk language |
| Edition-accurate feature claims | Selling Architecture-Ready as shipped |

---

## 5. Where brand must appear

- Installer splash / about  
- Welcome Wizard header  
- Website landing / pricing  
- Customer Portal chrome  
- Transactional email From/signatures  
- Legal documents & footer  
- Metadata / SEO / Open Graph  

Parent-company badges must **not** appear in footer or portal chrome.
