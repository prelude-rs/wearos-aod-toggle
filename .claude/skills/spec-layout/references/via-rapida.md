## Via rápida (the fast lane)

Part of the `spec-layout` skill — read when opening or registering a fast-lane change.

The formal flow (`spec → design → consistency → tasks → gates`) is right for design work, but
disproportionate for a small, low-risk change — fixing a stale test, tweaking config, correcting a
lint — where the ceremony costs more than the work and tempts the team to edit **outside** the kit and
lose the trail. The **via rápida** is a *sanctioned* informal lane: it lets the human + LLM edit the
policed files freely and captures the change **retroactively at the PR**, so `SOURCE-OF-TRUTH.md` and the
CHANGELOG stay true at minimal cost.

- **When it fits — a heuristic, never enforcement.** Small, low-risk, easily-reviewed changes. **The
  human decides** (never the agent, never a size heuristic): the kit does not auto-detect when a change
  "should" be fast. If a change carries design risk or touches a sensitive surface, use the formal flow.
- **Entry is a human decision, transcribed** — exactly like approval (see "Status field"). The human runs
  **`/via-rapida <change-id> "<justificativa>"`** (human-only: `disable-model-invocation`), which creates the
  lane's **single artifact** `specs/active/<change-id>/change.md` — straight into `active/`, never through
  `proposed/`, because the human's authorization clears it at birth (rule 1) — (from `templates/change.md`) with
  `Mode: fast`, a **mandatory non-empty `Justification:`**, and a stamped `<!-- authorized-by: … -->`
  marker. **The agent never opens the lane:** it does not stamp `authorized-by` nor invoke `fast-impl.sh` —
  same authority model as `! sdd-approve`, held by instruction (no hook denies it; the PR review is the
  control).
  **`/via-rapida` is still a slash-command, and the same risk stalks it — NOT measured.** Approval left
  the slash-command form because its `` !`bash …` `` body measured **1 success in 8** against the
  permission layer and the auto-mode classifier. `/via-rapida` has exactly that shape, and **nobody has
  run the equivalent measurement on it** — it carries a narrow allow-rule of its own, which may or may not
  be why it has not bitten. So this is a *declared unknown*, not a claim of safety: if the lane ever
  refuses to open, that is the first hypothesis, and giving it a launcher is a separate change
  (`2026-09-via-rapida-no-path`, epic 003 row L), deliberately not folded into the approval one because
  it would mean publishing `fast-impl.sh` and reversing the kit-only decision.
- **What it unlocks.** With an active `Mode: fast` change that is authorized, `require-approved-spec`
  releases edits to the policed files **without** `spec.md`/`design.md`/`consistency-report.md`/`tasks.md`.
  The release is **per-repo while the fast change exists** (identical to the formal loop, which also
  unlocks everything at the first approved change) — not per-file.
- **What it does NOT relax.** Branch + PR are still required (no direct merge to `dev`); commit
  conventions are unchanged (`Refs: <change-id>` still mandatory); **task-verify (at least L2)** still
  runs. Only the *artifact* that records the change is leaner.
- **Retroactive registration at the PR.** Fill `change.md` (what changed / why / the L2 verification
  commands + results), flip its `Verdict:` to `COMPLETE`, rewrite the declared SoT sections (rule 5(b)),
  append a CHANGELOG row with **`epic = fast`** plus its release-changelog item — or, for the release change,
  the declaration of its `seq` ("Changelog de release"),
  and `git mv` the folder to `specs/archive/`.
- **Archive gate.** `verify-archived-gates` accepts a `Mode: fast` archived folder with **only**
  `change.md` (`Verdict: COMPLETE` + non-empty `Justification:`), **dispensing** the formal
  `consistency-report.md` (PASS) and `evidence.md` (COMPLETE).
- **Auditable, not a silent default (R7).** `Mode: fast` is greppable in the archive folder's
  frontmatter, and each fast change shows `fast` in the CHANGELOG `epic` column — so the lane's use is
  always visible.
