/** THE GOLD MIND API — JavaScript sample (commercial only) */
async function tgmFetch(baseUrl, apiKey, path) {
  const res = await fetch(baseUrl + path, {
    headers: { Authorization: "Bearer " + apiKey, Accept: "application/json" },
  });
  if (!res.ok) throw new Error("TGM_API_" + res.status);
  return res.json();
}

module.exports = { tgmFetch };
