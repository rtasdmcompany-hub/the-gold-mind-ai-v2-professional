"use client";

import { upload } from "@vercel/blob/client";
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

async function uploadViaServerApi(file: File): Promise<string> {
  const fd = new FormData();
  fd.set("file", file);
  const res = await fetch("/api/site-content/upload", { method: "POST", body: fd });
  let json: { ok?: boolean; url?: string; error?: string } = {};
  try {
    json = (await res.json()) as typeof json;
  } catch {
    throw new Error(
      res.status === 413
        ? "File too large for server upload (use Blob / smaller file)."
        : `Upload failed (HTTP ${res.status}).`
    );
  }
  if (!res.ok || !json.ok || !json.url) {
    throw new Error(json.error || `Upload failed (HTTP ${res.status}).`);
  }
  return json.url;
}

async function uploadMediaFile(file: File, preferClientBlob: boolean): Promise<string> {
  // Direct-to-Blob for larger files (avoids Vercel ~4.5MB function body limit).
  if (preferClientBlob || file.size > 3_500_000) {
    try {
      const pathname = `site-content/${Date.now().toString(36)}-${file.name.replace(
        /[^a-zA-Z0-9._-]+/g,
        "-"
      )}`;
      const blob = await upload(pathname, file, {
        access: "public",
        handleUploadUrl: "/api/site-content/blob",
        contentType: file.type || undefined,
      });
      if (blob?.url) return blob.url;
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Blob upload failed";
      // Fall back to server API for small files / misconfigured blob.
      if (file.size > 4_200_000) throw new Error(msg);
    }
  }
  return uploadViaServerApi(file);
}

function UploadField({
  label,
  value,
  onChange,
  accept,
  disabled,
  preferClientBlob,
}: {
  label: string;
  value: string;
  onChange: (url: string) => void;
  accept: string;
  disabled?: boolean;
  preferClientBlob?: boolean;
}) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  const [okMsg, setOkMsg] = useState("");

  const onFile = async (file: File | null) => {
    if (!file || disabled) return;
    setBusy(true);
    setErr("");
    setOkMsg("");
    try {
      const url = await uploadMediaFile(file, !!preferClientBlob);
      onChange(url);
      setOkMsg(`Uploaded (${Math.max(1, Math.round(file.size / 1024))} KB)`);
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Upload failed");
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
        {okMsg ? <span className="meta" style={{ color: "#1b7a3d" }}>{okMsg}</span> : null}
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
    id: `ad_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`,
    enabled: true,
    title: "New ad",
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
  uploadHints: {
    blobConfigured: boolean;
    localWritable: boolean;
    durableMaxMb: number;
    clientUpload?: boolean;
  };
}) {
  const [ads, setAds] = useState<PhoneAd[]>(initial.phoneAds.ads);
  const [rotateOnEnd, setRotateOnEnd] = useState(initial.phoneAds.rotateOnEnd);
  const [hero, setHero] = useState(initial.hero);
  const [logos, setLogos] = useState(initial.logos);
  const [header, setHeader] = useState(initial.header);
  const [footer, setFooter] = useState(initial.footer);
  const preferClientBlob = uploadHints.clientUpload !== false && uploadHints.blobConfigured;

  const adsJson = useMemo(() => JSON.stringify(ads), [ads]);

  const updateAd = (idx: number, patch: Partial<PhoneAd>) => {
    setAds((prev) => prev.map((a, i) => (i === idx ? { ...a, ...patch } : a)));
  };

  return (
    <div className="stack" style={{ gap: 20 }}>
      <div className="card">
        <h2 style={{ marginTop: 0 }}>Upload engine</h2>
        <p className="meta">
          Blob: {uploadHints.blobConfigured ? "configured ✓ (direct video upload enabled)" : "missing"}
          {" · "}
          Local FS: {uploadHints.localWritable ? "writable" : "serverless"}
          {" · "}
          Small durable images: ≤ {uploadHints.durableMaxMb}MB
        </p>
        <p className="meta">
          Videos upload directly to Vercel Blob (up to ~80MB). After choosing a file, click{" "}
          <strong>Save phone ads</strong>. You can also paste any public HTTPS MP4 URL.
        </p>
      </div>

      {/* Phone ads playlist / relay */}
      <section className="card" id="phone-ads">
        <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
          <div>
            <h2 style={{ marginTop: 0 }}>iPhone video playlist (relay)</h2>
            <p className="meta">
              Ads play one after another (1 → 2 → 3 → … → 1). Add as many as you want (5, 6, or more).
              Nothing is removed until you click <strong>Delete Ad</strong> and save.
            </p>
          </div>
          {canWrite ? (
            <form action={actionResetSiteContentSection}>
              <input type="hidden" name="section" value="phoneAds" />
              <button type="submit" className="btn">Reset to default ad</button>
            </form>
          ) : null}
        </div>

        <p className="meta" style={{ marginBottom: 12 }}>
          Playlist size: <strong>{ads.length}</strong> · Enabled:{" "}
          <strong>{ads.filter((a) => a.enabled).length}</strong> · Order = play order
        </p>

        <label style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 16 }}>
          <input
            type="checkbox"
            checked={rotateOnEnd}
            disabled={!canWrite}
            onChange={(e) => setRotateOnEnd(e.target.checked)}
          />
          Relay mode — when a video ends, play the next ad (then loop)
        </label>

        {canWrite ? (
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 16 }}>
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => setAds((p) => [...p, emptyAd()])}
            >
              + Add Ad
            </button>
            <form action={actionSavePhoneAds}>
              <input type="hidden" name="adsJson" value={adsJson} />
              <input type="hidden" name="rotateOnEnd" value={rotateOnEnd ? "on" : ""} />
              <button type="submit" className="btn btn-primary">
                Save playlist
              </button>
            </form>
          </div>
        ) : null}

        {ads.length === 0 ? (
          <p className="meta">No ads in playlist. Click <strong>+ Add Ad</strong> to create the first one.</p>
        ) : null}

        {ads.map((ad, idx) => (
          <div
            key={ad.id}
            className="card"
            style={{ marginBottom: 12, background: "var(--surface-2, #f7f7f7)" }}
          >
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
              <strong>
                Ad #{idx + 1}
                <span className="meta"> / {ads.length}</span>
              </strong>
              <label style={{ display: "flex", gap: 6, alignItems: "center" }}>
                <input
                  type="checkbox"
                  checked={ad.enabled}
                  disabled={!canWrite}
                  onChange={(e) => updateAd(idx, { enabled: e.target.checked })}
                />
                Enabled in relay
              </label>
              {canWrite ? (
                <>
                  <button
                    type="button"
                    className="btn"
                    disabled={idx === 0}
                    onClick={() =>
                      setAds((p) => {
                        if (idx <= 0) return p;
                        const next = [...p];
                        [next[idx - 1], next[idx]] = [next[idx], next[idx - 1]];
                        return next;
                      })
                    }
                  >
                    ↑ Up
                  </button>
                  <button
                    type="button"
                    className="btn"
                    disabled={idx >= ads.length - 1}
                    onClick={() =>
                      setAds((p) => {
                        if (idx >= p.length - 1) return p;
                        const next = [...p];
                        [next[idx + 1], next[idx]] = [next[idx], next[idx + 1]];
                        return next;
                      })
                    }
                  >
                    ↓ Down
                  </button>
                  <button
                    type="button"
                    className="btn"
                    style={{ borderColor: "#b00020", color: "#b00020" }}
                    onClick={() => {
                      const label = ad.title || ad.id || `#${idx + 1}`;
                      if (
                        typeof window !== "undefined" &&
                        !window.confirm(`Delete Ad #${idx + 1} (${label}) from the playlist?`)
                      ) {
                        return;
                      }
                      setAds((p) => p.filter((_, i) => i !== idx));
                    }}
                  >
                    Delete Ad
                  </button>
                </>
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
                accept="video/mp4,video/webm,.mp4,.webm"
                disabled={!canWrite}
                preferClientBlob={preferClientBlob}
                onChange={(url) => updateAd(idx, { video: url })}
              />
              <UploadField
                label="Poster image"
                value={ad.poster}
                accept="image/*"
                disabled={!canWrite}
                preferClientBlob={preferClientBlob}
                onChange={(url) => updateAd(idx, { poster: url })}
              />
            </div>
            {!ad.video || !ad.poster ? (
              <p className="meta" style={{ color: "#a15c00", marginTop: 8 }}>
                Incomplete — needs video + poster before it plays on the homepage. It stays in the playlist until you
                delete it.
              </p>
            ) : null}
          </div>
        ))}

        {canWrite ? (
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 8 }}>
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => setAds((p) => [...p, emptyAd()])}
            >
              + Add Ad
            </button>
            <form action={actionSavePhoneAds}>
              <input type="hidden" name="adsJson" value={adsJson} />
              <input type="hidden" name="rotateOnEnd" value={rotateOnEnd ? "on" : ""} />
              <button type="submit" className="btn btn-primary">
                Save playlist
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
            accept="video/mp4,.mp4"
            disabled={!canWrite}
            preferClientBlob={preferClientBlob}
            onChange={(url) => setHero((h) => ({ ...h, backgroundMp4: url }))}
          />
          <UploadField
            label="Background WebM (optional)"
            value={hero.backgroundWebm}
            accept="video/webm,.webm"
            disabled={!canWrite}
            preferClientBlob={preferClientBlob}
            onChange={(url) => setHero((h) => ({ ...h, backgroundWebm: url }))}
          />
          <UploadField
            label="Poster image"
            value={hero.poster}
            accept="image/*"
            disabled={!canWrite}
            preferClientBlob={preferClientBlob}
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
            preferClientBlob={preferClientBlob}
            onChange={(url) => setLogos((l) => ({ ...l, header: url }))}
          />
          <UploadField
            label="Footer — Gold Mind"
            value={logos.footerGoldMind}
            accept="image/*"
            disabled={!canWrite}
            preferClientBlob={preferClientBlob}
            onChange={(url) => setLogos((l) => ({ ...l, footerGoldMind: url }))}
          />
          <UploadField
            label="Footer — RTAS Group"
            value={logos.footerRtasGroup}
            accept="image/*"
            disabled={!canWrite}
            preferClientBlob={preferClientBlob}
            onChange={(url) => setLogos((l) => ({ ...l, footerRtasGroup: url }))}
          />
          <UploadField
            label="Footer — RTAS Digital"
            value={logos.footerRtasDigital}
            accept="image/*"
            disabled={!canWrite}
            preferClientBlob={preferClientBlob}
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
