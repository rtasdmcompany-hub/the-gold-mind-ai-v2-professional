"use client";

import { useMemo, useState } from "react";
import type { PhoneAd } from "@/content/phone-ads";
import type { SiteContentData } from "@/server/site-content/types";
import {
  actionResetSiteContentSection,
  actionSaveHeaderFooter,
  actionSaveHero,
  actionSaveLogos,
  actionSavePhoneAds,
} from "@/server/site-content/actions";

function UploadField({
  label,
  value,
  onChange,
  accept,
  disabled,
}: {
  label: string;
  value: string;
  onChange: (url: string) => void;
  accept: string;
  disabled?: boolean;
}) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  const onFile = async (file: File | null) => {
    if (!file || disabled) return;
    setBusy(true);
    setErr("");
    try {
      const fd = new FormData();
      fd.set("file", file);
      const res = await fetch("/api/site-content/upload", { method: "POST", body: fd });
      const json = (await res.json()) as { ok?: boolean; url?: string; error?: string };
      if (!res.ok || !json.ok || !json.url) {
        setErr(json.error || "Upload failed");
        return;
      }
      onChange(json.url);
    } catch {
      setErr("Upload failed");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="field" style={{ flex: "1 1 280px" }}>
      <label>{label}</label>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="HTTPS URL or /media/… path"
        disabled={disabled}
      />
      <div style={{ display: "flex", gap: 8, alignItems: "center", marginTop: 6, flexWrap: "wrap" }}>
        <input
          type="file"
          accept={accept}
          disabled={disabled || busy}
          onChange={(e) => void onFile(e.target.files?.[0] || null)}
        />
        {busy ? <span className="meta">Uploading…</span> : null}
        {err ? <span className="meta" style={{ color: "#b00020" }}>{err}</span> : null}
      </div>
      {value ? (
        <p className="meta" style={{ marginTop: 4, wordBreak: "break-all" }}>
          Current: {value}
        </p>
      ) : null}
    </div>
  );
}

function emptyAd(): PhoneAd {
  return {
    id: `ad_${Date.now().toString(36)}`,
    enabled: true,
    title: "",
    details: "",
    href: "https://",
    video: "",
    poster: "",
  };
}

export function SiteContentAdminClient({
  initial,
  canWrite,
  uploadHints,
}: {
  initial: SiteContentData;
  canWrite: boolean;
  uploadHints: { blobConfigured: boolean; localWritable: boolean; durableMaxMb: number };
}) {
  const [ads, setAds] = useState<PhoneAd[]>(initial.phoneAds.ads);
  const [rotateOnEnd, setRotateOnEnd] = useState(initial.phoneAds.rotateOnEnd);
  const [hero, setHero] = useState(initial.hero);
  const [logos, setLogos] = useState(initial.logos);
  const [header, setHeader] = useState(initial.header);
  const [footer, setFooter] = useState(initial.footer);

  const adsJson = useMemo(() => JSON.stringify(ads), [ads]);

  const updateAd = (idx: number, patch: Partial<PhoneAd>) => {
    setAds((prev) => prev.map((a, i) => (i === idx ? { ...a, ...patch } : a)));
  };

  return (
    <div className="stack" style={{ gap: 20 }}>
      <div className="card">
        <h2 style={{ marginTop: 0 }}>Upload engine</h2>
        <p className="meta">
          Blob token: {uploadHints.blobConfigured ? "configured ✓" : "missing — set BLOB_READ_WRITE_TOKEN on Vercel for videos"}
          {" · "}
          Local FS: {uploadHints.localWritable ? "writable" : "serverless (no local public writes)"}
          {" · "}
          Small durable images: ≤ {uploadHints.durableMaxMb}MB in Redis
        </p>
        <p className="meta">
          Tip: phone/hero videos work best as public MP4 URLs or Vercel Blob uploads. You can also paste any HTTPS
          media URL without uploading.
        </p>
      </div>

      {/* Phone ads */}
      <section className="card" id="phone-ads">
        <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
          <div>
            <h2 style={{ marginTop: 0 }}>iPhone video panel ads</h2>
            <p className="meta">Rotating clickable videos on the homepage phone mockup.</p>
          </div>
          {canWrite ? (
            <form action={actionResetSiteContentSection}>
              <input type="hidden" name="section" value="phoneAds" />
              <button type="submit" className="btn">Reset ads to default</button>
            </form>
          ) : null}
        </div>

        <label style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 12 }}>
          <input
            type="checkbox"
            checked={rotateOnEnd}
            disabled={!canWrite}
            onChange={(e) => setRotateOnEnd(e.target.checked)}
          />
          Rotate to next ad when video ends
        </label>

        {ads.map((ad, idx) => (
          <div
            key={ad.id}
            className="card"
            style={{ marginBottom: 12, background: "var(--surface-2, #f7f7f7)" }}
          >
            <div style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "center" }}>
              <strong>Ad #{idx + 1}</strong>
              <label style={{ display: "flex", gap: 6, alignItems: "center" }}>
                <input
                  type="checkbox"
                  checked={ad.enabled}
                  disabled={!canWrite}
                  onChange={(e) => updateAd(idx, { enabled: e.target.checked })}
                />
                Enabled
              </label>
              {canWrite ? (
                <button type="button" className="btn" onClick={() => setAds((p) => p.filter((_, i) => i !== idx))}>
                  Remove
                </button>
              ) : null}
            </div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 12, marginTop: 10 }}>
              <div className="field" style={{ flex: "1 1 160px" }}>
                <label>ID</label>
                <input value={ad.id} disabled={!canWrite} onChange={(e) => updateAd(idx, { id: e.target.value })} />
              </div>
              <div className="field" style={{ flex: "1 1 220px" }}>
                <label>Title</label>
                <input value={ad.title} disabled={!canWrite} onChange={(e) => updateAd(idx, { title: e.target.value })} />
              </div>
              <div className="field" style={{ flex: "1 1 220px" }}>
                <label>Details line</label>
                <input
                  value={ad.details || ""}
                  disabled={!canWrite}
                  onChange={(e) => updateAd(idx, { details: e.target.value })}
                />
              </div>
              <div className="field" style={{ flex: "1 1 280px" }}>
                <label>Click URL</label>
                <input value={ad.href} disabled={!canWrite} onChange={(e) => updateAd(idx, { href: e.target.value })} />
              </div>
              <UploadField
                label="Video (mp4/webm)"
                value={ad.video}
                accept="video/mp4,video/webm"
                disabled={!canWrite}
                onChange={(url) => updateAd(idx, { video: url })}
              />
              <UploadField
                label="Poster image"
                value={ad.poster}
                accept="image/*"
                disabled={!canWrite}
                onChange={(url) => updateAd(idx, { poster: url })}
              />
            </div>
          </div>
        ))}

        {canWrite ? (
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            <button type="button" className="btn" onClick={() => setAds((p) => [...p, emptyAd()])}>
              + Add ad
            </button>
            <form action={actionSavePhoneAds}>
              <input type="hidden" name="adsJson" value={adsJson} />
              <input type="hidden" name="rotateOnEnd" value={rotateOnEnd ? "on" : ""} />
              <button type="submit" className="btn btn-primary">
                Save phone ads
              </button>
            </form>
          </div>
        ) : (
          <p className="meta">Read-only — need admin.launch.write</p>
        )}
      </section>

      {/* Hero */}
      <section className="card" id="hero">
        <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
          <div>
            <h2 style={{ marginTop: 0 }}>Hero background + headlines</h2>
            <p className="meta">Full-bleed hero video/poster and first-viewport copy.</p>
          </div>
          {canWrite ? (
            <form action={actionResetSiteContentSection}>
              <input type="hidden" name="section" value="hero" />
              <button type="submit" className="btn">Reset hero</button>
            </form>
          ) : null}
        </div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
          <UploadField
            label="Background MP4"
            value={hero.backgroundMp4}
            accept="video/mp4"
            disabled={!canWrite}
            onChange={(url) => setHero((h) => ({ ...h, backgroundMp4: url }))}
          />
          <UploadField
            label="Background WebM (optional)"
            value={hero.backgroundWebm}
            accept="video/webm"
            disabled={!canWrite}
            onChange={(url) => setHero((h) => ({ ...h, backgroundWebm: url }))}
          />
          <UploadField
            label="Poster image"
            value={hero.poster}
            accept="image/*"
            disabled={!canWrite}
            onChange={(url) => setHero((h) => ({ ...h, poster: url }))}
          />
          {(
            [
              ["eyebrow", "Eyebrow"],
              ["title", "Title"],
              ["lead", "Lead paragraph"],
              ["ctaPrimaryLabel", "Primary CTA label"],
              ["ctaPrimaryHref", "Primary CTA href"],
              ["ctaSecondaryLabel", "Secondary CTA label"],
              ["ctaSecondaryHref", "Secondary CTA href"],
            ] as const
          ).map(([key, label]) => (
            <div className="field" style={{ flex: key === "lead" ? "1 1 100%" : "1 1 240px" }} key={key}>
              <label>{label}</label>
              {key === "lead" ? (
                <textarea
                  rows={3}
                  value={hero[key]}
                  disabled={!canWrite}
                  onChange={(e) => setHero((h) => ({ ...h, [key]: e.target.value }))}
                />
              ) : (
                <input
                  value={hero[key]}
                  disabled={!canWrite}
                  onChange={(e) => setHero((h) => ({ ...h, [key]: e.target.value }))}
                />
              )}
            </div>
          ))}
        </div>
        {canWrite ? (
          <form action={actionSaveHero} style={{ marginTop: 12 }}>
            {Object.entries(hero).map(([k, v]) => (
              <input key={k} type="hidden" name={k} value={v} />
            ))}
            <button type="submit" className="btn btn-primary">
              Save hero
            </button>
          </form>
        ) : null}
      </section>

      {/* Logos */}
      <section className="card" id="logos">
        <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
          <div>
            <h2 style={{ marginTop: 0 }}>Logos</h2>
            <p className="meta">Header lockup + three footer brand marks.</p>
          </div>
          {canWrite ? (
            <form action={actionResetSiteContentSection}>
              <input type="hidden" name="section" value="logos" />
              <button type="submit" className="btn">Reset logos</button>
            </form>
          ) : null}
        </div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
          <UploadField
            label="Header logo"
            value={logos.header}
            accept="image/*"
            disabled={!canWrite}
            onChange={(url) => setLogos((l) => ({ ...l, header: url }))}
          />
          <UploadField
            label="Footer — Gold Mind"
            value={logos.footerGoldMind}
            accept="image/*"
            disabled={!canWrite}
            onChange={(url) => setLogos((l) => ({ ...l, footerGoldMind: url }))}
          />
          <UploadField
            label="Footer — RTAS Group"
            value={logos.footerRtasGroup}
            accept="image/*"
            disabled={!canWrite}
            onChange={(url) => setLogos((l) => ({ ...l, footerRtasGroup: url }))}
          />
          <UploadField
            label="Footer — RTAS Digital"
            value={logos.footerRtasDigital}
            accept="image/*"
            disabled={!canWrite}
            onChange={(url) => setLogos((l) => ({ ...l, footerRtasDigital: url }))}
          />
        </div>
        {canWrite ? (
          <form action={actionSaveLogos} style={{ marginTop: 12 }}>
            {Object.entries(logos).map(([k, v]) => (
              <input key={k} type="hidden" name={k} value={v} />
            ))}
            <button type="submit" className="btn btn-primary">
              Save logos
            </button>
          </form>
        ) : null}
      </section>

      {/* Header / footer copy */}
      <section className="card" id="copy">
        <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
          <div>
            <h2 style={{ marginTop: 0 }}>Header &amp; footer lines</h2>
            <p className="meta">Wordmark, nav CTA, footer description, copyright, risk line.</p>
          </div>
          {canWrite ? (
            <form action={actionResetSiteContentSection}>
              <input type="hidden" name="section" value="headerFooter" />
              <button type="submit" className="btn">Reset copy</button>
            </form>
          ) : null}
        </div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
          {(
            [
              ["brandName", "Header brand name", header.brandName, (v: string) => setHeader((h) => ({ ...h, brandName: v }))],
              ["brandSub", "Header subtitle", header.brandSub, (v: string) => setHeader((h) => ({ ...h, brandSub: v }))],
              ["ctaLabel", "Header CTA label", header.ctaLabel, (v: string) => setHeader((h) => ({ ...h, ctaLabel: v }))],
              ["ctaHref", "Header CTA href", header.ctaHref, (v: string) => setHeader((h) => ({ ...h, ctaHref: v }))],
            ] as const
          ).map(([key, label, value, set]) => (
            <div className="field" style={{ flex: "1 1 220px" }} key={key}>
              <label>{label}</label>
              <input value={value} disabled={!canWrite} onChange={(e) => set(e.target.value)} />
            </div>
          ))}
          <div className="field" style={{ flex: "1 1 100%" }}>
            <label>Footer description</label>
            <textarea
              rows={2}
              value={footer.description}
              disabled={!canWrite}
              onChange={(e) => setFooter((f) => ({ ...f, description: e.target.value }))}
            />
          </div>
          <div className="field" style={{ flex: "1 1 100%" }}>
            <label>Footer copyright line</label>
            <textarea
              rows={3}
              value={footer.copyrightLine}
              disabled={!canWrite}
              onChange={(e) => setFooter((f) => ({ ...f, copyrightLine: e.target.value }))}
            />
          </div>
          <div className="field" style={{ flex: "1 1 100%" }}>
            <label>Footer risk line</label>
            <input
              value={footer.riskLine}
              disabled={!canWrite}
              onChange={(e) => setFooter((f) => ({ ...f, riskLine: e.target.value }))}
            />
          </div>
        </div>
        {canWrite ? (
          <form action={actionSaveHeaderFooter} style={{ marginTop: 12 }}>
            <input type="hidden" name="brandName" value={header.brandName} />
            <input type="hidden" name="brandSub" value={header.brandSub} />
            <input type="hidden" name="ctaLabel" value={header.ctaLabel} />
            <input type="hidden" name="ctaHref" value={header.ctaHref} />
            <input type="hidden" name="description" value={footer.description} />
            <input type="hidden" name="copyrightLine" value={footer.copyrightLine} />
            <input type="hidden" name="riskLine" value={footer.riskLine} />
            <button type="submit" className="btn btn-primary">
              Save header &amp; footer
            </button>
          </form>
        ) : null}
      </section>
    </div>
  );
}
