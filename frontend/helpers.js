// Shared helpers available to every widget's JS wiring file.
// You don't need to understand this file -- just call the two functions.

async function callApi(endpoint, { method = "GET", body } = {}) {
  const opts = { method, headers: {} };
  if (body) {
    opts.headers["Content-Type"] = "application/json";
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(`/api/widgets/${endpoint}`, opts);
  return res.json();
}

function renderResult(elementId, result) {
  const el = document.getElementById(elementId);
  if (!el) return;
  if (!result.ok) {
    el.innerHTML = `<div class="widget-error">${escapeHtml(result.error || "something went wrong")}</div>`;
    return;
  }
  renderTable(elementId, result.rows || []);
}

function renderTable(elementId, rows) {
  const el = document.getElementById(elementId);
  if (!el) return;
  if (!rows.length) {
    el.innerHTML = `<div class="locked-message">No rows yet.</div>`;
    return;
  }
  const cols = Object.keys(rows[0]);
  const thead = `<tr>${cols.map((c) => `<th>${escapeHtml(c)}</th>`).join("")}</tr>`;
  const tbody = rows
    .map((r) => `<tr>${cols.map((c) => `<td>${escapeHtml(String(r[c] ?? ""))}</td>`).join("")}</tr>`)
    .join("");
  el.innerHTML = `<table class="widget-table"><thead>${thead}</thead><tbody>${tbody}</tbody></table>`;
}

function escapeHtml(str) {
  return str.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
