#!/usr/bin/env bash
# THE GOLD MIND REST examples — commercial /api/v1 only
BASE="${TGM_API_BASE:-https://api.example.com}"
KEY="${TGM_API_KEY:?set TGM_API_KEY}"

curl -s -H "Authorization: Bearer $KEY" "$BASE/api/v1/health"
curl -s -H "Authorization: Bearer $KEY" "$BASE/api/v1/profile"
curl -s -H "Authorization: Bearer $KEY" "$BASE/api/v1/licenses"
