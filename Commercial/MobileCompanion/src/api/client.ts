/**
 * Authenticated commercial API client — TLS only. No Core / trading endpoints.
 */
export type MobileApiConfig = { baseUrl: string; accessToken?: string };

export async function mobileFetch<T>(
  config: MobileApiConfig,
  path: string,
  init?: RequestInit
): Promise<T> {
  const res = await fetch(`${config.baseUrl}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(config.accessToken ? { Authorization: `Bearer ${config.accessToken}` } : {}),
      ...(init?.headers || {}),
    },
  });
  if (!res.ok) throw new Error(`MOBILE_API_${res.status}`);
  const json = await res.json();
  return json.data as T;
}
