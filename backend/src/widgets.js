const fs = require("fs");
const path = require("path");
const yaml = require("js-yaml");
const { pool } = require("./db");

const ROOT = process.env.APP_ROOT || path.resolve(__dirname, "..", "..");
const REGISTRY_PATH = path.join(ROOT, "widgets.yaml");

function loadRegistry() {
  const raw = fs.readFileSync(REGISTRY_PATH, "utf8");
  const doc = yaml.load(raw);
  const flat = [];
  for (const [week, widgets] of Object.entries(doc.weeks || {})) {
    for (const w of widgets) {
      flat.push({ week, ...w });
    }
  }
  return flat;
}

function findWidget(week, id) {
  return loadRegistry().find((w) => w.week === week && w.id === id);
}

function readSql(widget) {
  return fs.readFileSync(path.join(ROOT, widget.sql), "utf8");
}

// Minimal, safe-enough literal escaping for the teaching-sandbox action
// scripts (weeks 3/8/9). This is NOT how you'd do it in production -- a real
// app parameterizes every value through the driver. We can't do that here
// because these files are multi-statement scripts (DDL + DML mixed), and the
// simple query protocol doesn't support bind parameters. Values are limited
// to what students type into the demo forms on their own local sandbox.
function quoteLiteral(value) {
  const str = String(value ?? "");
  return "'" + str.replace(/'/g, "''") + "'";
}

function substituteParams(sql, params, paramNames) {
  let result = sql;
  for (const name of paramNames || []) {
    const token = new RegExp(":" + name + "\\b", "g");
    result = result.replace(token, quoteLiteral(params[name]));
  }
  return result;
}

async function runQueryWidget(widget) {
  const sql = readSql(widget);
  const client = await pool.connect();
  try {
    const result = await client.query(sql);
    const rows = result.rows ?? (Array.isArray(result) ? result[result.length - 1].rows : []);
    return { ok: true, rows, unlocked: rows.length >= (widget.min_rows ?? 1) };
  } finally {
    client.release();
  }
}

async function runActionWidget(widget, body) {
  let sql = readSql(widget);
  sql = substituteParams(sql, body || {}, widget.params);

  // Widgets that switch Postgres role (e.g. the RLS week) may need part of
  // their script to run with full privileges first (DDL setup: creating
  // roles/policies) and only the rest under the restricted role. Mark that
  // boundary in the .sql file with a line containing ONLY the marker
  // (matched as a whole line, not a substring, so mentioning it in a comment
  // elsewhere in the file doesn't accidentally trigger a split there).
  const markerLine = /^--\s*@switch-role\s*$/m;
  const match = sql.match(markerLine);
  const setupSql = match ? sql.slice(0, match.index) : null;
  const mainSql = match ? sql.slice(match.index + match[0].length) : sql;

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    if (setupSql) {
      await client.query(setupSql);
    }

    if (widget.session) {
      for (const cfg of widget.session.set_config || []) {
        const val = (body || {})[cfg.param] ?? "";
        await client.query("SELECT set_config($1, $2, true)", [cfg.key, String(val)]);
      }
      if (widget.session.role_param) {
        const requestedRole = (body || {})[widget.session.role_param];
        const allowed = widget.session.allowed_roles || [];
        if (requestedRole && allowed.includes(requestedRole)) {
          // Safe: requestedRole is checked against a fixed config whitelist,
          // never interpolated from arbitrary user input directly.
          await client.query(`SET ROLE ${requestedRole}`);
        }
      }
    }

    const result = await client.query(mainSql);
    if (widget.session && widget.session.role_param) {
      await client.query("RESET ROLE").catch(() => {});
    }
    await client.query("COMMIT");

    const rows = result.rows ?? (Array.isArray(result) ? result[result.length - 1].rows : []);
    return { ok: true, rows };
  } catch (err) {
    await client.query("ROLLBACK").catch(() => {});
    return { ok: false, error: err.message };
  } finally {
    client.release();
  }
}

module.exports = { loadRegistry, findWidget, runQueryWidget, runActionWidget, ROOT, substituteParams, quoteLiteral };
