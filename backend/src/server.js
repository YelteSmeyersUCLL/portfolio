const express = require("express");
const cors = require("cors");
const path = require("path");
const { loadRegistry, findWidget, runQueryWidget, runActionWidget, ROOT } = require("./widgets");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/widgets", (_req, res) => {
  const registry = loadRegistry().map(({ week, id, kind, title, sql, js }) => ({ week, id, kind, title, sql, js }));
  res.json(registry);
});

app.get("/widgets/:week/:id", async (req, res) => {
  const widget = findWidget(req.params.week, req.params.id);
  if (!widget) return res.status(404).json({ ok: false, error: "unknown widget" });
  if (widget.kind !== "query") return res.status(400).json({ ok: false, error: "use POST for action widgets" });

  try {
    const result = await runQueryWidget(widget);
    res.json(result);
  } catch (err) {
    res.json({ ok: false, unlocked: false, error: err.message });
  }
});

app.post("/widgets/:week/:id", async (req, res) => {
  const widget = findWidget(req.params.week, req.params.id);
  if (!widget) return res.status(404).json({ ok: false, error: "unknown widget" });
  if (widget.kind !== "action") return res.status(400).json({ ok: false, error: "this widget doesn't take POST" });

  const result = await runActionWidget(widget, req.body);
  res.json(result);
});

app.get("/health", (_req, res) => res.json({ ok: true }));

// "Run full check" button. Reuses the exact same grading logic as `make
// test` and CI -- same reset-and-verify pass, just triggered from the
// browser instead of a terminal. NOTE: this resets the database to seed
// state as part of running (same trade-off as `make test`), so any demo
// data from clicking around the dashboard (a placed order, a refund) gets
// reset too. The frontend re-fetches widget state after this completes so
// the UI reflects the reset, rather than showing stale "unlocked" cards.
app.post("/check", async (_req, res) => {
  try {
    // The backend is a LONG-RUNNING process, but grading/run_tests.js,
    // grading/checks.js, and the widgets/db modules they internally
    // require are all edited constantly during development (and are
    // bind-mounted, so edits ARE on disk immediately) -- Node's require()
    // cache would otherwise keep serving whatever version was loaded the
    // very first time each was ever required, ignoring every edit since.
    // Bust all four before requiring, so every check click re-reads
    // current files, same as the CLI/`make test` always does (that runs
    // as a fresh one-shot process, so it never has this problem at all).
    // widgets.js and db.js are busted via THIS file's own relative path --
    // require.cache is keyed by resolved absolute path, not the relative
    // string used to get there, so this hits the exact same cache entry
    // run_tests.js's own internal require() of them resolves to.
    const runTestsPath = require.resolve(path.join(ROOT, "grading", "run_tests"));
    const checksPath = require.resolve(path.join(ROOT, "grading", "checks"));
    const widgetsPath = require.resolve("./widgets");
    const dbPath = require.resolve("./db");
    delete require.cache[runTestsPath];
    delete require.cache[checksPath];
    delete require.cache[widgetsPath];
    delete require.cache[dbPath];
    const { runChecks } = require(runTestsPath);
    const { results, passed, failed } = await runChecks();
    res.json({ ok: true, results, passed, failed });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`databasement backend listening on :${port}`));
