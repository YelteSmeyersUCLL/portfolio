// Regenerates grading/expected/*.json from whatever is CURRENTLY in sql/ --
// paste the correct solution into a widget's .sql file, run this, and it
// captures the live output as the new "expected" fixture.
//
// Uses the SAME executeCheck() core run_tests.js uses to grade -- so
// "what gets captured" and "what gets compared later" can never drift
// apart the way two separately hand-written copies eventually did.
//
// Needed any time the underlying seed data changes (a new dataset, a
// transform script, adding rows) -- every fixture is a frozen snapshot of
// one specific query's output, and it silently goes stale the moment the
// data underneath it changes. Re-run this after any such change, for every
// widget the data change affects (usually: all of them).
//
// Usage (from the repo root or grading/, same as run_tests.js):
//   1. Paste the correct SQL for a widget into its sql/weekNN/widget.sql
//   2. DATABASE_URL=... node grading/capture_fixtures.js [week/id]
//      (omit the filter to recapture every widget in checks.js)
//   3. Restore the stub (TODO) version of the .sql file once you're done
//      capturing -- this tool does not do that for you.
//
// This does NOT compare anything or report pass/fail -- it just writes
// whatever the current .sql file produces as the new ground truth. Running
// it against a wrong/unfinished .sql file will happily capture a wrong
// fixture, so double check what you're capturing.
const fs = require("fs");
const path = require("path");
const { executeCheck, pool, resetDb } = require("./run_tests");
const checks = require("./checks");

const EXPECTED_DIR = path.join(__dirname, "expected");

function writeFixture(relPath, rows) {
  const full = path.join(EXPECTED_DIR, relPath);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, JSON.stringify(rows, null, 2));
  console.log(`  wrote ${relPath} (${rows.length} rows)`);
}

async function main() {
  const filter = process.argv[2];
  const toRun = filter ? checks.filter((c) => `${c.week}/${c.id}` === filter) : checks;
  if (filter && toRun.length === 0) {
    console.error(`no check matches "${filter}"`);
    process.exit(1);
  }

  let failed = 0;
  let needsReset = true;
  let geolocationLoaded = false; // see run_tests.js's runChecks for why this
  // needs to be tracked separately from needsReset
  for (const check of toRun) {
    const label = `${check.week}/${check.id}`;
    console.log(`${label}:`);
    const wantsGeolocation = !!check.needsGeolocation;
    const mustReset = needsReset || (wantsGeolocation && !geolocationLoaded);
    try {
      const slots = await executeCheck(check, { skipReset: !mustReset });
      if (mustReset) geolocationLoaded = wantsGeolocation;
      needsReset = !!check.action;
      for (const slot of slots) {
        if (slot.countCheck) {
          console.log(`  (countQuery case -- nothing to capture, computed live at grading time)`);
        } else {
          writeFixture(slot.expected, slot.rows);
        }
      }
    } catch (err) {
      needsReset = true; // be safe: an error might mean a partial mutation happened
      console.log(`  FAILED to capture ${label}: ${err.message}`);
      failed++;
    }
  }

  // Same reasoning as run_tests.js's runChecks: leave the shared database
  // (the same one a student's live dashboard reads) in a complete state
  // when done, regardless of which check's reset-skipping optimization ran
  // last.
  resetDb();

  console.log(`\ncaptured ${toRun.length - failed}/${toRun.length}`);
  await pool.end();
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
