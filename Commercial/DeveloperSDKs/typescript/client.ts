/** THE GOLD MIND API — TypeScript sample (commercial only) */
export async function tgmFetch<T>(baseUrl: string, apiKey: string, path: string): Promise<T> {
  const res = await fetch(`${baseUrl}${path}`, {
    headers: { Authorization: `Bearer ${apiKey}`, Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`TGM_API_${res.status}`);
  const json = await res.json();
  return json.data as T;
}
