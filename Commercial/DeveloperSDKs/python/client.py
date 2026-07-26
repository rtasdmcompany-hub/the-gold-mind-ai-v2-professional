"""THE GOLD MIND API — Python sample (commercial only)."""
import urllib.request
import json

def tgm_fetch(base_url: str, api_key: str, path: str):
    req = urllib.request.Request(
        base_url + path,
        headers={"Authorization": f"Bearer {api_key}", "Accept": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))
