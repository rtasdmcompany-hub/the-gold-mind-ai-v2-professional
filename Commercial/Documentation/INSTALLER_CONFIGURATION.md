# INSTALLER_CONFIGURATION.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Production portal:** https://the-gold-mind-ai-v2-professional.vercel.app

| Setting | Value | Location |
|---------|-------|----------|
| Portal base URL | `https://the-gold-mind-ai-v2-professional.vercel.app` | `inno/payload/config/portal.json` |
| Build script default | same production URL | `scripts/Build-CommercialRelease.ps1` `-PortalBase` |
| Google login launch | `{portal}/login?provider=google` | `Activate-License.ps1 -GoogleLogin` |
| Activation API | `{portal}/api/licenses/actions` | `Activate-License.ps1` |
| Update check | `{portal}/api/releases/check` | `Update-TheGoldMindProfessional.ps1` |

**Rule:** Never package `thegoldmind.ai` until that custom domain is DNS-pointed at this Vercel project.
