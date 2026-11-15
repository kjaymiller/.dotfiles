#!/usr/bin/env node
/**
 * Fetches OpenRouter spend and writes ~/.cache/openrouter-spend.html
 * Used by the pi /spend extension and by the systemd timer that keeps
 * the background widget fresh. Reads OPENROUTER_MANAGEMENT_KEY if set,
 * falls back to the key stored in ~/.pi/agent/auth.json.
 *
 * The HTML auto-refreshes every 5 minutes via meta refresh.
 */

import { homedir } from "node:os";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { join } from "node:path";

const ACTIVITY_URL = "https://openrouter.ai/api/v1/activity";
const CREDITS_URL = "https://openrouter.ai/api/v1/credits";
const DASHBOARD_URL = "https://openrouter.ai/activity";
const KEYS_URL = "https://openrouter.ai/settings/keys";
const HTML_PATH = join(homedir(), ".cache", "openrouter-spend.html");
const JSON_PATH = join(homedir(), ".cache", "openrouter-spend.json");
const REFRESH_SECS = 300;

async function apiGet(url, key) {
  const res = await fetch(url, { headers: { Authorization: `Bearer ${key}` } });
  const body = await res.json();
  if (!res.ok) throw new Error(body?.error?.message ?? `HTTP ${res.status}`);
  return body;
}

async function loadKeys() {
  const keys = [];
  if (process.env.OPENROUTER_MANAGEMENT_KEY) keys.push(process.env.OPENROUTER_MANAGEMENT_KEY);
  try {
    const auth = JSON.parse(await readFile(join(homedir(), ".pi", "agent", "auth.json"), "utf8"));
    if (auth?.openrouter?.key) keys.push(auth.openrouter.key);
  } catch {
    /* no stored key */
  }
  return keys;
}

async function fetchSpend() {
  const now = new Date();
  const monthStart = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}-01`;
  const today = now.toISOString().slice(0, 10);
  const monthLabel = now.toLocaleString("en-US", { month: "long", year: "numeric", timeZone: "UTC" });

  const data = {
    monthLabel, monthStart, today,
    byModel: [], monthlyTotal: 0, hasPerModel: false, perModelError: undefined,
    lifetimeUsage: 0, lifetimeCredits: 0, creditsError: undefined,
    generatedAt: new Date().toISOString(),
  };

  const keys = await loadKeys();

  for (const key of keys) {
    try {
      const byModel = new Map();
      let monthlyTotal = 0;
      for (let page = 1; page <= 50; page++) {
        const body = await apiGet(`${ACTIVITY_URL}?page=${page}`, key);
        const rows = body?.data ?? [];
        if (rows.length === 0) break;
        for (const row of rows) {
          if (row.date < monthStart) continue;
          monthlyTotal += row.usage ?? 0;
          for (const [model, cost] of Object.entries(row.by_model ?? {})) {
            byModel.set(model, (byModel.get(model) ?? 0) + (cost ?? 0));
          }
        }
      }
      data.byModel = [...byModel.entries()].sort((a, b) => b[1] - a[1]);
      data.monthlyTotal = monthlyTotal;
      data.hasPerModel = true;
      break;
    } catch (e) {
      data.perModelError = String(e?.message ?? e);
    }
  }

  if (keys.length > 0) {
    try {
      const body = await apiGet(CREDITS_URL, keys[keys.length - 1]);
      data.lifetimeUsage = body?.data?.total_usage ?? 0;
      data.lifetimeCredits = body?.data?.total_credits ?? 0;
    } catch (e) {
      data.creditsError = String(e?.message ?? e);
    }
  } else {
    data.creditsError = "No OpenRouter key found";
  }

  return data;
}

const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const money = (n) => (n >= 100 ? `$${n.toFixed(2)}` : `$${n.toFixed(4)}`);

function renderHtml(d) {
  const max = Math.max(...d.byModel.map(([, v]) => v), 0.0001);
  const colors = ["#8b5cf6", "#06b6d4", "#f59e0b", "#10b981", "#ec4899", "#f97316", "#3b82f6", "#14b8a6"];

  const bars = d.byModel
    .slice(0, 12)
    .map(([model, cost], i) => {
      const pct = Math.max((cost / max) * 100, 1.5);
      const color = colors[i % colors.length];
      const name = model.length > 42 ? model.slice(0, 40) + "…" : model;
      return `<div class="row">
  <div class="label" title="${esc(model)}">${esc(name)}</div>
  <div class="track"><div class="bar" style="width:${pct.toFixed(1)}%;background:${color}"></div></div>
  <div class="cost">${money(cost)}</div>
</div>`;
    })
    .join("\n");

  const remaining = Math.max(d.lifetimeCredits - d.lifetimeUsage, 0);
  const usedPct = d.lifetimeCredits > 0 ? Math.min((d.lifetimeUsage / d.lifetimeCredits) * 100, 100) : 0;

  const perModelSection = d.hasPerModel
    ? d.byModel.length === 0
      ? `<div class="empty">No usage recorded this month yet 🎉</div>`
      : `${bars}
<div class="row total">
  <div class="label">TOTAL</div>
  <div class="track"></div>
  <div class="cost">${money(d.monthlyTotal)}</div>
</div>`
    : `<div class="notice">
  <p><b>Per-model breakdown needs a Management Key</b></p>
  <p class="small">Create one at <a href="${KEYS_URL}">openrouter.ai/settings/keys</a>, then:<br>
  <code>export OPENROUTER_MANAGEMENT_KEY=sk-or-v1-…</code></p>
</div>`;

  return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>OpenRouter Spend</title>
<meta http-equiv="refresh" content="${REFRESH_SECS}">
<style>
  :root { color-scheme: dark; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: "Inter", "Segoe UI", system-ui, sans-serif;
    background: #0d1117; color: #e6edf3;
    padding: 28px; min-width: 520px;
  }
  .card { max-width: 640px; margin: 0 auto; }
  h1 { font-size: 20px; font-weight: 600; letter-spacing: -0.3px; }
  .dates { color: #7d8590; font-size: 13px; margin-top: 4px; }
  section { margin-top: 26px; }
  h2 { font-size: 12px; text-transform: uppercase; letter-spacing: 1.2px;
       color: #7d8590; margin-bottom: 12px; font-weight: 600; }
  .row { display: grid; grid-template-columns: 220px 1fr 84px;
         align-items: center; gap: 12px; margin-bottom: 8px; }
  .label { font-size: 13px; color: #e6edf3; white-space: nowrap;
           overflow: hidden; text-overflow: ellipsis; direction: rtl; text-align: left; }
  .track { background: #161b22; border-radius: 6px; height: 22px; overflow: hidden; }
  .bar { height: 100%; border-radius: 6px; }
  .cost { font-size: 13px; text-align: right; font-variant-numeric: tabular-nums;
          color: #b8c4d0; }
  .row.total { border-top: 1px solid #21262d; padding-top: 12px; margin-top: 12px; }
  .row.total .label { font-weight: 700; }
  .row.total .cost { color: #fff; font-weight: 700; font-size: 15px; }
  .meter { background: #161b22; border-radius: 6px; height: 10px; overflow: hidden;
           margin: 10px 0 8px; }
  .meter > div { height: 100%; border-radius: 6px;
                 background: linear-gradient(90deg, #8b5cf6, #06b6d4); }
  .legend { display: flex; justify-content: space-between; font-size: 13px;
            color: #b8c4d0; }
  .empty { color: #7d8590; font-size: 14px; padding: 20px 0; }
  .notice { background: #161b22; border: 1px solid #21262d; border-radius: 10px;
            padding: 16px; font-size: 14px; }
  .notice .small { color: #7d8590; font-size: 12.5px; margin-top: 8px; }
  code { background: #0d1117; padding: 2px 6px; border-radius: 5px;
         font-size: 12px; color: #79c0ff; }
  a { color: #58a6ff; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .actions { margin-top: 28px; display: flex; gap: 10px; }
  .btn { display: inline-block; padding: 9px 16px; border-radius: 8px;
         font-size: 13.5px; font-weight: 600; text-decoration: none !important; }
  .btn.primary { background: #8b5cf6; color: #fff; }
  .btn.primary:hover { background: #7c3aed; }
  .btn.ghost { border: 1px solid #30363d; color: #b8c4d0; }
  .btn.ghost:hover { border-color: #8b949e; color: #fff; }
  .err { color: #f85149; font-size: 12.5px; margin-top: 10px; }
  .updated { color: #484f58; font-size: 11px; margin-top: 22px; text-align: center; }
</style>
</head>
<body>
<div class="card">
  <h1>OpenRouter Spend</h1>
  <div class="dates">${esc(d.monthLabel)} &middot; ${esc(d.monthStart)} → ${esc(d.today)} (UTC)</div>

  <section>
    <h2>Spend by model — ${esc(d.monthLabel)}</h2>
    ${perModelSection}
    ${d.perModelError && !d.hasPerModel ? `<div class="err">${esc(d.perModelError)}</div>` : ""}
  </section>

  <section>
    <h2>Account balance</h2>
    <div class="meter"><div style="width:${usedPct.toFixed(1)}%"></div></div>
    <div class="legend">
      <span>Used ${money(d.lifetimeUsage)}</span>
      <span>Remaining ${money(remaining)} of ${money(d.lifetimeCredits)}</span>
    </div>
    ${d.creditsError ? `<div class="err">${esc(d.creditsError)}</div>` : ""}
  </section>

  <div class="actions">
    <a class="btn primary" href="${DASHBOARD_URL}">Open OpenRouter Activity ↗</a>
    <a class="btn ghost" href="${KEYS_URL}">Manage Keys</a>
  </div>
  <div class="updated">auto-refreshes every 5 min &middot; updated ${new Date().toLocaleTimeString("en-US")}</div>
</div>
</body>
</html>`;
}

try {
  const data = await fetchSpend();
  await mkdir(join(homedir(), ".cache"), { recursive: true });
  await writeFile(HTML_PATH, renderHtml(data), "utf8");
  await writeFile(JSON_PATH, JSON.stringify(data, null, 2), "utf8");
  console.log(`written: ${HTML_PATH} (${data.hasPerModel ? `${data.byModel.length} models, $${data.monthlyTotal.toFixed(4)} this month` : `lifetime $${data.lifetimeUsage.toFixed(2)}`})`);
} catch (e) {
  console.error(`failed: ${e?.message ?? e}`);
  process.exit(1);
}
