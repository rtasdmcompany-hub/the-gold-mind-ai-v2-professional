/**
 * Persist Site Content JSON to Vercel Blob when Upstash is unavailable.
 * Ads/playlist survive until admin deletes them.
 */
import { head, put } from "@vercel/blob";

const CONTENT_PATH = "cms/site-content-v1.json";
const MEDIA_PATH = "cms/site-media-v1.json";

function blobReady(): boolean {
  return !!(process.env.BLOB_READ_WRITE_TOKEN || "").trim();
}

async function readBlobJson(pathname: string): Promise<string | null> {
  if (!blobReady()) return null;
  try {
    const meta = await head(pathname, { token: process.env.BLOB_READ_WRITE_TOKEN });
    const res = await fetch(meta.url, { cache: "no-store" });
    if (!res.ok) return null;
    return await res.text();
  } catch {
    return null;
  }
}

async function writeBlobJson(pathname: string, body: string): Promise<boolean> {
  if (!blobReady()) return false;
  try {
    await put(pathname, body, {
      access: "public",
      contentType: "application/json; charset=utf-8",
      addRandomSuffix: false,
      allowOverwrite: true,
      token: process.env.BLOB_READ_WRITE_TOKEN,
      cacheControlMaxAge: 60,
    });
    return true;
  } catch (e) {
    console.warn("[site-content] blob persist failed", e instanceof Error ? e.message : e);
    return false;
  }
}

export async function blobGetSiteContent(): Promise<string | null> {
  return readBlobJson(CONTENT_PATH);
}

export async function blobSetSiteContent(json: string): Promise<boolean> {
  return writeBlobJson(CONTENT_PATH, json);
}

export async function blobGetMediaIndex(): Promise<string | null> {
  return readBlobJson(MEDIA_PATH);
}

export async function blobSetMediaIndex(json: string): Promise<boolean> {
  return writeBlobJson(MEDIA_PATH, json);
}

export function isBlobPersistConfigured(): boolean {
  return blobReady();
}
