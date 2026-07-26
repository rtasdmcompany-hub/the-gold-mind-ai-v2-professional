<?php
/** THE GOLD MIND API — PHP sample (commercial only) */
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
