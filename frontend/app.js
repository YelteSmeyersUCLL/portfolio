const WEEK_TITLES = {
  week01: "Week 1–2 · Joins & aggregation",
  week02: "Week 2 · HAVING & aggregate filters",
  week03: "Week 3 · Transactions",
  week04: "Week 4 · Subqueries & CTEs",
  week05: "Week 5 · Window functions",
  week06: "Week 6 · Performance & views",
  week08: "Week 8 · Security (RLS)",
  week09: "Week 9 · Procedures & triggers",
  week10: "Week 10 · DDL",
};

// Bespoke markup for action-type widgets — the interactive bit students'
// small JS wiring files attach to. Query widgets don't need an entry here;
// they get a generic table container.
const ACTION_MARKUP = {
  place_order: `
    <div class="widget-action-row">
      <button id="week03-place-order-btn">Place demo order</button>
    </div>
    <div id="week03-place-order-result"></div>`,
  rls_role_switch: `
    <div class="widget-action-row">
      <label class="widget-action-field">
        <span>Role</span>
        <select id="week08-role-select">
          <option value="app_customer">app_customer</option>
          <option value="app_district_admin">app_district_admin</option>
          <option value="app_admin">app_admin</option>
        </select>
      </label>
      <label class="widget-action-field">
        <span id="week08-value-label">Person (customer_unique_id)</span>
        <input id="week08-person-id" placeholder="paste a real customer_unique_id" />
      </label>
      <button id="week08-role-switch-btn">View orders</button>
    </div>
    <div id="week08-rls-result"></div>`,
  process_refund: `
    <div class="widget-action-row">
      <label class="widget-action-field">
        <span>Order ID</span>
        <input id="week09-order-id" placeholder="paste a real order_id" />
      </label>
      <button id="week09-refund-btn">Process refund</button>
    </div>
    <div id="week09-refund-result"></div>`,
  mark_delivered: `
    <div class="widget-action-row">
      <label class="widget-action-field">
        <span>Order ID</span>
        <input id="week09-deliver-order-id" placeholder="paste a real, non-delivered order_id" />
      </label>
      <button id="week09-deliver-btn">Mark delivered</button>
    </div>
    <div id="week09-deliver-result"></div>`,
  rls_seller_view: `
    <div class="widget-action-row">
      <label class="widget-action-field">
        <span>Seller ID</span>
        <input id="week08-seller-id" placeholder="paste a real seller_id" />
      </label>
      <button id="week08-seller-view-btn">View items</button>
    </div>
    <div id="week08-seller-result"></div>`,
};

function widgetFilePath(w) {
  return w.kind === "action" ? w.sql : w.sql;
}

// Widgets that exist on the dashboard but aren't part of the autograded set
// (order_audit_log's "locked" state is just "has the trigger fired yet",
// not something to solve/grade -- see grading/checks.js).
const UNGRADED_WIDGET_IDS = ["order_audit_log"];

function renderPendingChecks(registry) {
  const graded = registry.filter((w) => !UNGRADED_WIDGET_IDS.includes(w.id));
  const rows = graded
    .map((w) => `<div class="check-row pending"><span class="dot"></span><span class="label">${w.week}/${w.id}</span></div>`)
    .join("");
  document.getElementById("check-results").innerHTML = `
    <div class="check-summary">${graded.length} widgets — not checked yet</div>
    <div class="check-list">${rows}</div>`;
}

async function loadWidgets(refreshCheckPanel = true) {
  const registry = await fetch("/api/widgets").then((r) => r.json());
  if (refreshCheckPanel) renderPendingChecks(registry);
  const byWeek = {};
  for (const w of registry) {
    (byWeek[w.week] ||= []).push(w);
  }

  const main = document.getElementById("weeks");
  main.innerHTML = "";

  for (const week of Object.keys(WEEK_TITLES)) {
    if (!byWeek[week]) continue;
    const section = document.createElement("section");
    section.className = "week-section";
    section.innerHTML = `<h2>${WEEK_TITLES[week]}</h2><div class="widget-grid"></div>`;
    const grid = section.querySelector(".widget-grid");

    for (const w of byWeek[week]) {
      const card = document.createElement("div");
      card.className = "widget-card locked";
      card.id = `card-${week}-${w.id}`;
      grid.appendChild(card);

      if (w.kind === "query") {
        renderQueryWidget(card, w);
      } else {
        renderActionWidget(card, w);
      }
    }
    main.appendChild(section);
  }
}

async function renderQueryWidget(card, w) {
  let res;
  try {
    res = await fetch(`/api/widgets/${w.week}/${w.id}`).then((r) => r.json());
  } catch {
    res = { ok: false };
  }
  const refresh = () => renderQueryWidget(card, w);
  if (res.ok && res.unlocked) {
    card.classList.remove("locked");
    card.classList.add("unlocked");
    card.innerHTML = `<h3><span class="status-dot"></span>${w.title}${refreshButtonHtml()}</h3><div class="widget-body"></div>`;
    renderTable(setBodyId(card), res.rows);
    wireRefreshButton(card, refresh);
  } else {
    renderLocked(card, w, res.error, refresh);
  }
}

function wireRefreshButton(card, onRefresh) {
  const btn = card.querySelector(".widget-refresh-btn");
  if (btn) btn.addEventListener("click", onRefresh);
}

function refreshButtonHtml() {
  return `<button class="widget-refresh-btn" type="button" title="Check again">↻</button>`;
}

function setBodyId(card) {
  const body = card.querySelector(".widget-body");
  const id = `${card.id}-body`;
  body.id = id;
  return id;
}

// `onRefresh`, if given, adds a ↻ button that re-runs whatever check makes
// sense for this card -- re-polling the query for a query widget, or
// retrying the script load for an action widget whose .js 404'd. Wiring
// lives HERE, not in each caller, specifically so every call site gets a
// working button automatically rather than each caller having to remember
// to attach the listener itself (a real bug we hit once already: the
// action-widget error path below used to render the button without ever
// wiring it, so it just sat there doing nothing).
function renderLocked(card, w, error, onRefresh) {
  card.className = "widget-card locked";
  card.innerHTML = `
    <h3><span class="status-dot"></span>${w.title}${onRefresh ? refreshButtonHtml() : ""}</h3>
    <div class="locked-message">
      🔧 not wired up yet.
      <span class="widget-file">${w.sql}</span>
      ${error ? `<div class="widget-error">${error}</div>` : ""}
    </div>`;
  if (onRefresh) wireRefreshButton(card, onRefresh);
}

function renderActionWidget(card, w) {
  card.className = "widget-card unlocked";
  card.innerHTML = `<h3><span class="status-dot"></span>${w.title}</h3>${ACTION_MARKUP[w.id] || ""}`;

  if (!w.js) return;
  const script = document.createElement("script");
  // Cache-busting query param: these per-widget scripts are loaded
  // dynamically (not declared in index.html), and a hard refresh doesn't
  // reliably force browsers to re-fetch dynamically-added <script> tags the
  // way it does for the main page's own declared resources. A different
  // URL (different query string) is NEVER served from cache by any
  // browser -- this makes staleness structurally impossible here, rather
  // than relying on everyone remembering to hard-refresh every time a
  // widget's .js file changes.
  script.src = `/sql/${w.week}/${w.js.split("/").pop()}?v=${Date.now()}`;
  script.onerror = () => renderLocked(card, w, "sql/" + w.week + "/" + w.js.split("/").pop() + " not found yet", () => renderActionWidget(card, w));
  document.body.appendChild(script);
}

loadWidgets();

document.getElementById("run-check-btn").addEventListener("click", async () => {
  const btn = document.getElementById("run-check-btn");
  const resultsEl = document.getElementById("check-results");
  btn.disabled = true;
  btn.textContent = "Checking... (this resets the database)";
  resultsEl.innerHTML = "";

  try {
    const res = await fetch("/api/check", { method: "POST" }).then((r) => r.json());
    if (!res.ok) {
      resultsEl.innerHTML = `<div class="widget-error">${res.error || "check failed to run"}</div>`;
    } else {
      const rows = res.results
        .map((r) => `<div class="check-row ${r.pass ? "pass" : "fail"}">
            <span class="dot"></span><span class="label">${r.label}</span>
          </div>${!r.pass && r.error ? `<pre class="check-error">${escapeHtml(r.error)}</pre>` : ""}`)
        .join("");
      resultsEl.innerHTML = `
        <div class="check-summary">${res.passed} / ${res.passed + res.failed} widgets verified correct</div>
        <div class="check-list">${rows}</div>`;
    }
  } catch {
    resultsEl.innerHTML = `<div class="widget-error">Couldn't reach the backend to run the check.</div>`;
  } finally {
    btn.disabled = false;
    btn.textContent = "Run full check";
    // the check just reset the database -- refresh cards so the dashboard
    // reflects that instead of showing stale pre-reset state. Don't touch
    // the check-results panel itself -- it already has the real results.
    loadWidgets(false);
  }
});
