/**
 * Write official SDK samples + Postman collection under Commercial/DeveloperSDKs.
 */
import fs from "fs";
import path from "path";
import { brand } from "@/lib/brand";
import { commercialRoot } from "@/server/phase11/store";

export function writeSdkSamples(): string {
  const root = path.join(commercialRoot(), "DeveloperSDKs");
  const dirs = ["javascript", "typescript", "python", "csharp", "php", "postman"];
  for (const d of dirs) {
    const p = path.join(root, d);
    if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
  }

  fs.writeFileSync(
    path.join(root, "README.md"),
    `# ${brand.brandName} Developer SDKs

Official integration samples for the Enterprise API Platform (\`/api/v1\`).

**Commercial APIs only** — trading execution, strategy, and Core services are never exposed.

## Languages

- JavaScript
- TypeScript
- Python
- C#
- PHP
- Postman collection
- REST curl examples (see \`rest-examples.sh\`)
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(root, "javascript", "client.js"),
    `/** ${brand.brandName} API — JavaScript sample (commercial only) */
async function tgmFetch(baseUrl, apiKey, path) {
  const res = await fetch(baseUrl + path, {
    headers: { Authorization: "Bearer " + apiKey, Accept: "application/json" },
  });
  if (!res.ok) throw new Error("TGM_API_" + res.status);
  return res.json();
}

module.exports = { tgmFetch };
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(root, "typescript", "client.ts"),
    `/** ${brand.brandName} API — TypeScript sample (commercial only) */
export async function tgmFetch<T>(baseUrl: string, apiKey: string, path: string): Promise<T> {
  const res = await fetch(\`\${baseUrl}\${path}\`, {
    headers: { Authorization: \`Bearer \${apiKey}\`, Accept: "application/json" },
  });
  if (!res.ok) throw new Error(\`TGM_API_\${res.status}\`);
  const json = await res.json();
  return json.data as T;
}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(root, "python", "client.py"),
    `"""${brand.brandName} API — Python sample (commercial only)."""
import urllib.request
import json
import { brand } from "@/lib/brand";

def tgm_fetch(base_url: str, api_key: str, path: str):
    req = urllib.request.Request(
        base_url + path,
        headers={"Authorization": f"Bearer {api_key}", "Accept": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(root, "csharp", "TgmClient.cs"),
    `// ${brand.brandName} API — C# sample (commercial only)
using System.Net.Http;
using System.Net.Http.Headers;

public class TgmClient {
  private readonly HttpClient _http = new HttpClient();
  public TgmClient(string baseUrl, string apiKey) {
    _http.BaseAddress = new System.Uri(baseUrl);
    _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
  }
  public async System.Threading.Tasks.Task<string> GetAsync(string path) {
    var res = await _http.GetAsync(path);
    res.EnsureSuccessStatusCode();
    return await res.Content.ReadAsStringAsync();
  }
}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(root, "php", "client.php"),
    `<?php
/** ${brand.brandName} API — PHP sample (commercial only) */
function tgm_fetch(string $baseUrl, string $apiKey, string $path): array {
  $ch = curl_init($baseUrl . $path);
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
      "Authorization: Bearer {$apiKey}",
      "Accept: application/json",
    ],
  ]);
  $body = curl_exec($ch);
  curl_close($ch);
  return json_decode($body, true) ?? [];
}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(root, "rest-examples.sh"),
    `#!/usr/bin/env bash
# ${brand.brandName} REST examples — commercial /api/v1 only
BASE="\${TGM_API_BASE:-https://api.example.com}"
KEY="\${TGM_API_KEY:?set TGM_API_KEY}"

curl -s -H "Authorization: Bearer $KEY" "$BASE/api/v1/health"
curl -s -H "Authorization: Bearer $KEY" "$BASE/api/v1/profile"
curl -s -H "Authorization: Bearer $KEY" "$BASE/api/v1/licenses"
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(root, "postman", "tgm-api-v1.postman_collection.json"),
    JSON.stringify(
      {
        info: {
          name: `${brand.brandName} API v1`,
          description: "Commercial APIs only — Core Trading Engine isolated",
          schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
        },
        variable: [
          { key: "baseUrl", value: "http://localhost:3000" },
          { key: "apiKey", value: "tgm_live_xxx" },
        ],
        item: [
          {
            name: "Health",
            request: {
              method: "GET",
              header: [{ key: "Authorization", value: "Bearer {{apiKey}}" }],
              url: "{{baseUrl}}/api/v1/health",
            },
          },
          {
            name: "Profile",
            request: {
              method: "GET",
              header: [{ key: "Authorization", value: "Bearer {{apiKey}}" }],
              url: "{{baseUrl}}/api/v1/profile",
            },
          },
          {
            name: "Licenses",
            request: {
              method: "GET",
              header: [{ key: "Authorization", value: "Bearer {{apiKey}}" }],
              url: "{{baseUrl}}/api/v1/licenses",
            },
          },
          {
            name: "OAuth Token",
            request: {
              method: "POST",
              header: [{ key: "Content-Type", value: "application/json" }],
              body: {
                mode: "raw",
                raw: '{"grant_type":"client_credentials","api_key":"{{apiKey}}"}',
              },
              url: "{{baseUrl}}/api/v1/oauth/token",
            },
          },
        ],
      },
      null,
      2
    ),
    "utf8"
  );

  return root;
}
