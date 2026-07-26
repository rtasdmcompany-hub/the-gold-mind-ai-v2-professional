/**
 * Official brand asset integration for THE GOLD MIND AI v2.0 PROFESSIONAL.
 * Source: Owner-uploaded official logos. Does not touch Trading Engine / Core.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import sharp from "sharp";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(webRoot, "..", "..", "..");
const cursorAssets = path.join(
  process.env.USERPROFILE || "",
  ".cursor",
  "projects",
  "h-PERSONAL-RTAS-Digital-Marketing-Company-RTAS-Softwear-THE-GOLD-MIND-AI-v2-0-Professional",
  "assets"
);

function findSource(substr) {
  const files = fs.readdirSync(cursorAssets);
  const hit = files.find((f) => f.toLowerCase().includes(substr.toLowerCase()));
  if (!hit) throw new Error(`Missing source asset matching: ${substr}`);
  const full = path.join(cursorAssets, hit);
  if (!fs.existsSync(full)) throw new Error(`Source listed but missing on disk: ${full}`);
  return full;
}

async function stageSource(label, substr) {
  const src = findSource(substr);
  const staged = path.join(webRoot, ".brand-src", `${label}${path.extname(src)}`);
  await ensureDir(path.dirname(staged));
  fs.copyFileSync(src, staged);
  const st = fs.statSync(staged);
  if (st.size < 100) throw new Error(`Staged source too small: ${staged}`);
  console.log("staged", label, st.size, "bytes");
  return staged;
}

async function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

async function writePng(input, outPath, opts = {}) {
  let img = sharp(input);
  if (opts.width || opts.height) {
    img = img.resize({
      width: opts.width,
      height: opts.height,
      fit: opts.fit || "contain",
      background: opts.background ?? { r: 0, g: 0, b: 0, alpha: 0 },
    });
  }
  if (opts.flatten) {
    img = img.flatten({ background: opts.flatten });
  }
  await ensureDir(path.dirname(outPath));
  await img.png({ compressionLevel: 9, quality: 100 }).toFile(outPath);
  console.log("wrote", path.relative(repoRoot, outPath));
}

async function writeIcoFromPng(pngPath, icoPath, sizes = [16, 32, 48, 256]) {
  // Minimal multi-size ICO writer (PNG-compressed entries)
  const entries = [];
  for (const size of sizes) {
    const buf = await sharp(pngPath)
      .resize(size, size, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .png()
      .toBuffer();
    entries.push({ size, buf });
  }
  const headerSize = 6;
  const dirSize = 16 * entries.length;
  let offset = headerSize + dirSize;
  const header = Buffer.alloc(headerSize);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(entries.length, 4);
  const dirs = [];
  const bodies = [];
  for (const e of entries) {
    const dir = Buffer.alloc(16);
    dir.writeUInt8(e.size >= 256 ? 0 : e.size, 0);
    dir.writeUInt8(e.size >= 256 ? 0 : e.size, 1);
    dir.writeUInt8(0, 2);
    dir.writeUInt8(0, 3);
    dir.writeUInt16LE(1, 4);
    dir.writeUInt16LE(32, 6);
    dir.writeUInt32LE(e.buf.length, 8);
    dir.writeUInt32LE(offset, 12);
    dirs.push(dir);
    bodies.push(e.buf);
    offset += e.buf.length;
  }
  await ensureDir(path.dirname(icoPath));
  fs.writeFileSync(icoPath, Buffer.concat([header, ...dirs, ...bodies]));
  console.log("wrote", path.relative(repoRoot, icoPath));
}

async function main() {
  const srcLight = await stageSource("the-gold-mind-light", "The_Gold_Mind_Logo_white-");
  const srcDark = await stageSource("the-gold-mind-dark", "The_Gold_Mind_Logo_squire_black-");
  const srcGroup = await stageSource("rtas-group", "surcle_rtas_group-");
  const srcDm = await stageSource("rtas-dm", "PNG.RTAS_DM_Company_Logo");

  const brandWeb = path.join(webRoot, "public", "brand");
  const brandApp = path.join(webRoot, "src", "app");
  const brandCommercial = path.join(repoRoot, "Commercial", "Assets", "Brand");
  const marketIcons = path.join(repoRoot, "Commercial", "Assets", "Market", "Icons");
  const marketLogos = path.join(repoRoot, "Commercial", "Assets", "Market", "Logos");
  const installerIcons = path.join(repoRoot, "Commercial", "Installer", "Professional", "assets", "brand");
  const docsBrand = path.join(repoRoot, "Commercial", "Documentation", "Brand");
  const eaBrand = path.join(repoRoot, "Commercial", "Assets", "EA");

  // Masters
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-logo-dark.png"));
  await writePng(srcLight, path.join(brandWeb, "the-gold-mind-logo-light.png"));
  await writePng(srcGroup, path.join(brandWeb, "rtas-group-project-badge.png"));
  await writePng(srcDm, path.join(brandWeb, "rtas-digital-marketing-logo.png"));

  // Header / nav (compact height)
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-logo-header.png"), {
    height: 64,
    fit: "inside",
  });
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-logo-nav.png"), {
    width: 180,
    height: 72,
    fit: "contain",
  });
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-logo-login.png"), {
    width: 320,
    height: 320,
    fit: "contain",
  });
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-logo-footer.png"), {
    height: 48,
    fit: "inside",
  });
  await writePng(srcGroup, path.join(brandWeb, "rtas-group-footer-badge.png"), {
    height: 56,
    fit: "inside",
  });
  await writePng(srcDm, path.join(brandWeb, "rtas-digital-marketing-footer.png"), {
    height: 48,
    fit: "inside",
  });

  // Dashboard / portal mark
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-mark-128.png"), {
    width: 128,
    height: 128,
    fit: "cover",
  });

  // Icons / PWA / SEO
  for (const size of [16, 32, 48, 64, 128, 180, 192, 256, 512]) {
    await writePng(srcDark, path.join(brandWeb, `the-gold-mind-icon-${size}.png`), {
      width: size,
      height: size,
      fit: "cover",
    });
  }

  // Open Graph / social
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-og-1200x630.png"), {
    width: 1200,
    height: 630,
    fit: "contain",
    flatten: { r: 11, g: 11, b: 12 },
  });
  await writePng(srcDark, path.join(brandWeb, "the-gold-mind-twitter-1200x600.png"), {
    width: 1200,
    height: 600,
    fit: "contain",
    flatten: { r: 11, g: 11, b: 12 },
  });

  // Next.js App Router metadata files
  await writePng(srcDark, path.join(brandApp, "icon.png"), { width: 512, height: 512, fit: "cover" });
  await writePng(srcDark, path.join(brandApp, "apple-icon.png"), { width: 180, height: 180, fit: "cover" });
  await writePng(srcDark, path.join(brandApp, "opengraph-image.png"), {
    width: 1200,
    height: 630,
    fit: "contain",
    flatten: { r: 11, g: 11, b: 12 },
  });
  await writePng(srcDark, path.join(brandApp, "twitter-image.png"), {
    width: 1200,
    height: 600,
    fit: "contain",
    flatten: { r: 11, g: 11, b: 12 },
  });

  // Favicon ico
  await writeIcoFromPng(
    path.join(brandWeb, "the-gold-mind-icon-256.png"),
    path.join(webRoot, "public", "favicon.ico"),
    [16, 32, 48, 256]
  );
  fs.copyFileSync(path.join(webRoot, "public", "favicon.ico"), path.join(brandWeb, "favicon.ico"));

  // Commercial brand library
  const commercialCopies = [
    ["the-gold-mind-logo-dark.png", path.join(brandCommercial, "the-gold-mind-logo-dark.png")],
    ["the-gold-mind-logo-light.png", path.join(brandCommercial, "the-gold-mind-logo-light.png")],
    ["rtas-group-project-badge.png", path.join(brandCommercial, "rtas-group-project-badge.png")],
    ["rtas-digital-marketing-logo.png", path.join(brandCommercial, "rtas-digital-marketing-logo.png")],
    ["the-gold-mind-og-1200x630.png", path.join(brandCommercial, "social", "the-gold-mind-og-1200x630.png")],
    ["the-gold-mind-icon-512.png", path.join(brandCommercial, "icons", "the-gold-mind-icon-512.png")],
    ["favicon.ico", path.join(brandCommercial, "icons", "favicon.ico")],
  ];
  for (const [src, dest] of commercialCopies) {
    await ensureDir(path.dirname(dest));
    fs.copyFileSync(path.join(brandWeb, src), dest);
    console.log("copied", path.relative(repoRoot, dest));
  }

  // Market / MQL5
  await ensureDir(marketIcons);
  await ensureDir(marketLogos);
  fs.copyFileSync(path.join(brandWeb, "the-gold-mind-icon-512.png"), path.join(marketIcons, "tgm-market-icon.png"));
  await writePng(srcDark, path.join(marketLogos, "tgm-market-logo.png"), {
    width: 1280,
    height: 720,
    fit: "contain",
    flatten: { r: 11, g: 11, b: 12 },
  });
  await writePng(srcDark, path.join(marketLogos, "tgm-market-cover.png"), {
    width: 1920,
    height: 1080,
    fit: "contain",
    flatten: { r: 11, g: 11, b: 12 },
  });

  // Installer / Windows
  await writeIcoFromPng(
    path.join(brandWeb, "the-gold-mind-icon-256.png"),
    path.join(installerIcons, "the-gold-mind-app.ico"),
    [16, 32, 48, 256]
  );
  fs.copyFileSync(
    path.join(brandWeb, "the-gold-mind-logo-dark.png"),
    path.join(installerIcons, "the-gold-mind-installer-banner.png")
  );

  // EA branding (commercial assets only — not Core MQ5)
  await ensureDir(eaBrand);
  fs.copyFileSync(path.join(brandWeb, "the-gold-mind-icon-128.png"), path.join(eaBrand, "the-gold-mind-ea-icon-128.png"));
  fs.copyFileSync(path.join(brandWeb, "the-gold-mind-logo-dark.png"), path.join(eaBrand, "the-gold-mind-ea-logo.png"));

  // Documentation
  await ensureDir(docsBrand);
  fs.copyFileSync(path.join(brandWeb, "the-gold-mind-logo-light.png"), path.join(docsBrand, "the-gold-mind-logo-light.png"));
  fs.copyFileSync(path.join(brandWeb, "the-gold-mind-logo-dark.png"), path.join(docsBrand, "the-gold-mind-logo-dark.png"));
  fs.copyFileSync(path.join(brandWeb, "rtas-group-project-badge.png"), path.join(docsBrand, "rtas-group-project-badge.png"));

  // Site webmanifest
  const manifest = {
    name: "THE GOLD MIND AI v2.0 PROFESSIONAL",
    short_name: "GOLD MIND",
    description: "Official Customer Portal for THE GOLD MIND PROFESSIONAL by RTAS.",
    start_url: "/",
    display: "standalone",
    background_color: "#0b0b0c",
    theme_color: "#c6a75e",
    icons: [
      { src: "/brand/the-gold-mind-icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/brand/the-gold-mind-icon-512.png", sizes: "512x512", type: "image/png" },
    ],
  };
  fs.writeFileSync(path.join(webRoot, "public", "site.webmanifest"), JSON.stringify(manifest, null, 2));
  console.log("Brand asset integration complete.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
