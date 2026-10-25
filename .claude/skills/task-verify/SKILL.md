---
name: task-verify
description: MANDATORY leveled mechanical verification — L0, L1, L2, L3. Consult at implementation start of every change (L0), after completing any task in tasks.md before marking it Done, before opening a PR to dev, and before promoting to main.
---

# Task Verification (Leveled Mechanical Gates)

Verify that work meets its mechanical quality bar before it advances a lifecycle stage. **The levels below are constant across every Sellers repo; the concrete commands are project-local** — fill the "Commands by subproject" section per repo, the same way `git-practices` defers project CI commands. Announce you are using `task-verify`.

> Harvested from the Sellers `team-task-verify` standard (shared across the `/team`-family repos). This is the *mechanical* counterpart to `validation-gate`: task-verify answers "do the checks pass?" repeatedly during the loop; `validation-gate` answers "does the deliverable match the spec?" once at the end.

## Verification levels

### Level 0 — Baseline (before implementation starts)
Run once per change, at implementation start: after Gate 1.5, with the ledger generated (`check-tasks.sh --ledger`), on the
branch freshly cut from `dev`, BEFORE the first implementation task. It proves the starting
point was green — an L2 failure later is never again ambiguous inheritance.

1. Run the **L2 set** — lint + tests + build/type-check — for each affected subproject, on
   the untouched base (no change commits yet).

**Pass criteria:** all exit 0.

**Red baseline → the human decides, on the spot.** If any check fails, STOP before any task:
report exactly what is red (command, output, subproject) and present the choice — fix the
baseline first (a trivial fix or its own change), or explicitly accept the failures as
known-red. The agent never proceeds on its own.

**Record it.** Either way, fill the "Baseline (L0)" section of the change's `evidence.md`:
base SHA, commands + results per subproject, and — if red — the human's decision (items
tolerated, name, date). Implementation never starts without this record.

**Reuse instead of re-running.** If the L2 set is already proven green at the SAME base
commit SHA — e.g. a recorded L2 run at that SHA, or an archived change's L2 evidence at it;
a CI run counts only as Level 2 below says —, cite that evidence in the Baseline (L0) section
(reference + SHA) instead of re-running locally.
Freshness is SHA-identity only — never a time window ("recent" or "today" do not qualify).

### Level 1 — Task acceptance (during coding, on the feature branch)
Run after each task in `tasks.md` is completed, **before marking it Done**. This is the in-development checkpoint that drives the validate-and-code cycle.

1. **Lint** the changed code in the affected subproject.
2. **Tests** for the affected subproject (at minimum the module/package touched).

**Pass criteria:** all exit 0.

### Level 2 — Pre-PR to `dev` (all tasks in the change done)
Everything in L1 across the whole change, plus:

3. **Build / type-check** the deliverable for each affected subproject (binary, bundle, container image, migration plan — whichever applies).
4. **Full test suite** green.

**Pass criteria:** all exit 0. L2 is the whole set, run locally. The CI `build-check` may run only
part of it — the kit's runs the portable checks and only the suites the PR can break — so
a green CI counts as a green L2 only when the project's CI runs the whole set.

### Level 3 — Pre-PR to `main` (promotion to production)
Everything in L2, plus readonly smoke tests against a running instance (health/readiness probes, key endpoints reachable).

**Pass criteria:** all commands exit 0; health returns ok.

## Commands by subproject (fill per repo)

Subprojeto único: app Kotlin nativo Wear OS (Gradle).

- Prereqs/env: JDK 17, Android SDK (`ANDROID_HOME`), Gradle wrapper (`./gradlew`)
- L1 lint: `./gradlew ktlintCheck detekt lintDebug`
- L1 test: `./gradlew testDebugUnitTest`
- L2 build: `./gradlew assembleRelease`
- L2 test: `./gradlew test`
- L3 smoke: `./gradlew connectedDebugAndroidTest` (emulador/dispositivo Wear OS via adb)
- Artifact smoke: `./gradlew assembleRelease && adb install -r app/build/outputs/apk/release/*.apk`

### Stack-conditional guidance (never substitute a weaker check)
- **Python:** run `ruff check`, not just `ruff format`. Format-only misses import ordering, unused imports, type-annotation rules.
- **Go:** run `golangci-lint`, not `go vet`; pin the version CI uses; run `gofumpt` on changed files before committing.
- **TypeScript / JS:** run the linter **and** the type checker (`tsc --noEmit`); type errors don't surface through lint alone.
- **Rust:** `cargo fmt --check` + `cargo clippy --all-targets -- -D warnings` + `cargo test`.

## Rules

1. Never mark a task **Done** without passing **L1**.
2. Never open a PR to `dev` without passing **L2**.
3. Never open a PR to `main` without passing **L3**.
4. Use the linter actually configured for the subproject — never fall back to a weaker check.
5. Report exact failures: which lint rules + files, which tests + why, which build/type errors.
6. New or changed code must have corresponding tests; report untested paths.
7. **Run in a CI-equivalent environment — local-green ≠ CI-green.** A local `.env`, exported secrets, or shell vars CI won't have can mask env-dependent behavior and produce false greens. Run the suite the way CI does (no `.env`, no extra env) — e.g. move `.env` aside or clear the vars. *(Pilot lesson: a mutual-exclusion test passed locally only because `.env` supplied `ORACLE_*`; CI, with a clean env, failed it — and a real CLI ordering bug hid behind it.)*
8. **Exercise the deployed artifact, not just the source tree — *verify the real artifact, not a proxy*** (the principle behind rule 7, applied to packaging). For a **packaged deliverable** (one installed/deployed as a built package or image, not run from the source tree), a level (L2 for `dev`, L3 for `main`) must **build the artifact and exercise the built/installed form** — non-editable install into a clean venv, or the built image; run the entrypoint; and for **packaged data assert it is present in the artifact** (e.g. inspect the wheel/image). An editable install (`pip install -e`) resolves files from the source tree and **hides packaging/path bugs**. *(Pilot lesson: a tenant-config TOML resolved fine under editable install but wasn't shipped in the wheel → the deployed extractor crashed in production; the fix added a non-editable build-and-load smoke that greps the wheel.)* Record the project-local command on the `Artifact smoke` line above; if it can't run in-env, mark it `DEFERRED` with the exact command, not green.
9. **Never start implementation without a recorded L0** — green, or red + the human's recorded
   decision (see Level 0; the record lives in evidence.md "Baseline (L0)").
10. **Unfilled commands = the level FAILS, never advisory** (see "Commands by subproject").

## Relationship to the rest of the kit
- **`validation-gate`** — its "Regression standing" step *is* L2 (or L3 when promoting to main). Run `task-verify` and cite its output there instead of re-specifying commands.
- **`git-practices`** — its pre-PR local check is "`task-verify` at the level for the target branch" (L2 for `dev`, L3 for `main`).
- **CI** — the `build-check` status the org ruleset requires — what it proves about L2: Level 2 above.

## Output

1. Verification level applied (L0 / L1 / L2 / L3).
2. Per-check results — PASS or FAIL with details.
3. Per-task verdict: PASS / FAIL / PARTIAL.
4. Missing coverage or untested paths.
5. `tasks.md` update recommendations (which tasks to mark Done).
6. Blockers found during verification.
