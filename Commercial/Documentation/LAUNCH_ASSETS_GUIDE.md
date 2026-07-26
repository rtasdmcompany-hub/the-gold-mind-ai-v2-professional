# LAUNCH_ASSETS_GUIDE.md

**Phase 8 · Sprint 9**  
**Brand:** Premium Black · Metallic Gold · official THE GOLD MIND / RTAS marks only  
**Rule:** Architecture for assets — place binaries under `Commercial/Assets/` when Owner supplies  

---

## 1. Asset inventory

| Asset | Use | Status |
|-------|-----|--------|
| Product Logo Usage | Web · installer · about · PDF | Spec READY · files often NOT STARTED |
| Icons | App · tray · file types · Market | NOT STARTED |
| Splash Screen | Installer / first launch | Spec READY · art NOT STARTED |
| About Dialog | Version · edition · RTAS · Core freeze note | Spec READY |
| Application Metadata | File description · company · version resource | IN PROGRESS |
| Installer Branding | Sidebar · header · finish page | Spec READY |
| Desktop Shortcut | Professional only (optional) · naming | Spec READY |
| PDF Branding | Manuals · reports export | Spec READY (Sprint 5) |
| Report Branding | Analytics PDF header/footer | Spec READY |

---

## 2. Logo usage rules

| Do | Don’t |
|----|-------|
| Use Owner-supplied official files | Recreate / recolor logo freely |
| Clear space around mark | Stretch / add glow / fake 3D |
| Gold-on-black or mono as kit allows | Place on busy photo without shield |

---

## 3. Splash / About

**Splash:** Brand mark · product name · short tagline (“Automated Trading Software”) · no feature spam  

**About:**  
`THE GOLD MIND PROFESSIONAL {version}`  
`RTAS Group of Companies`  
`Core Trading Engine: sole execution authority`  
Demo/Live not required here  

---

## 4. Metadata (Windows / package)

| Field | Example |
|-------|---------|
| Product name | THE GOLD MIND PROFESSIONAL |
| Company | RTAS Group of Companies |
| File version | Match SemVer |
| Copyright | © RTAS … |

---

## 5. Shortcut

Name: `THE GOLD MIND PROFESSIONAL`  
Icon: official app icon  
Target: launcher/installer-defined — never a raw unprotected license file  

---

## 6. PDF / Report chrome

- Header: wordmark + edition  
- Footer: page · version · disclaimer line  
- Print-friendly: reduce gold ink (Sprint 5 Export)  

---

## 7. Folder convention

```
Commercial/Assets/
  Brand/
  Icons/
  Splash/
  Store/Screenshots/
  Market/Screenshots/
```

---

*End of LAUNCH_ASSETS_GUIDE.md*
