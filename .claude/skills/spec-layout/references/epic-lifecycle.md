## Epic lifecycle

Part of the `spec-layout` skill — read when authoring, approving, decomposing, executing, closing or reopening an epic.

The **change** half of the flow is well-trodden (the `CLAUDE.md` diagram + `spec-layout` → "Structure" and "Rules"). The **epic** half is documented here so a team — and the agent — can run it with the same confidence. An epic (`specs/epics/NNN-<name>.md`) is a long-lived initiative too big for one change: it holds the product-level WHAT, the settled decisions, the invariants every child change inherits, and a decomposition map. Epics are *context, not flow participants* (rule 4) — they are never implemented directly; their changes are.

- **Authoring.** When an initiative is too big for one change (see the change-vs-epic trigger in rule 2), author an epic file at **`specs/epics/NNN-<name>.md`** by applying the **Socratic discipline of `spec-brainstorming`** (the Confusion Protocol — never infer requirements, never guess) to produce **product intent + settled decisions + invariants + a decomposition map** (the list of changes it will spawn). **Numbering: `NNN` is a zero-padded three-digit ordinal (`001`, `002`, …), monotonic, assigned at authoring as the highest number that has **ever** existed in `specs/epics/` plus one — deleted and renamed epics included — and *never reused*** (same discipline as the CHANGELOG `seq`). **The epic id is the file's full slug (`NNN-<name>`, no `.md`), and it is permanent:** the ledger's `epic` column, the `Epic:` line and the links cite it, and the archive and ledger are insert-only, so an epic is never renumbered. `.claude/hooks/check-epic-numbering.sh`, delegated to by `verify-archived-gates.sh` on every PR, bars a collision **on the PR that brings the epic**: a name outside `NNN-<name>.md`, a repeated number or a repeated name, a new epic at or below the historical maximum, and a renumbering (a new epic carrying the name of one the PR removed). A collision that already circulated is declared, **by a human, never by the agent or the adoption tooling**, in `specs/epics/LEGADO-NUMERACAO.md`, one pair per line (every line starting with ``- ` `` is read as a declaration, so the file holds no examples); a collision born in the PR is not declarable — the new epic is renamed before its id circulates. On a promotion to `main` in a repo with a `dev` branch, the PR rules are not re-applied (the epic was checked on its PR to `dev`); the tree rules are. **Known gap:** without "require branches to be up to date" in the org ruleset (measured off on the kit's and bko's `dev` and `main`, 2026-09-30), two PRs racing for the same number both pass, and the collision surfaces on the next PR as an old one; turning that ruleset option on closes it. A
renumbering split across two PRs (one deletes `004-x`, a later one adds `009-x`) is not caught either: each
PR alone is a deletion and a new epic, both allowed; the doctrine forbids it and review is what holds it. *This is new doctrine:* there is no formal `spec-brainstorming`-for-epics and no `templates/epic.md` — anchor the shape on the existing exemplar **`specs/epics/002-sdd-adoption.md`**, not on a template that doesn't exist. The discipline is `spec-brainstorming`'s; the *output* is the epic file.
  **Three destinations, and the test that sorts them.** The map holds *changes*. Two siblings hold what is
  not a change yet: **fog** (`## Fog / Not yet specified`) for in-scope questions you feel coming but cannot
  phrase sharply, and **out-of-scope** for work ruled past the destination. **The fog-or-ticket test:** *can
  you state the question precisely now?* — **not** *can you answer it*. Sharp-but-blocked earns a **row**;
  vague stays fog. Fog **graduates**; out-of-scope **never** does. A fog entry is a **question** — anything
  else belongs in one of the other two. This convention fixes the **role**, not the label: name the sections
  in the team's language (`004` uses `### Fora de escopo deste épico`).
  **This is mid-flight discovery, not reopening.** Reopening a *closed* epic was already normal (see Closing,
  `002` precedent); what these sections cover is discovery while children are **in flight**, which until now
  arrived as an amendment to the map instead of a graduation.
- **Approving.** The approve decision is the human's, transcribed — same principle as the change artifacts (see "Status field"). **Current reality (honest — do not pretend otherwise):** the launcher has **no `epic` subcommand**. So an epic is approved by the human **editing its `Status:` field by hand**. *(Forward-ref: an `epic` subcommand + hook enforcement for epics is future work, tracked separately — not built yet.)*
- **Decomposing.** Each line of the decomposition map becomes one change folder (born in `specs/proposed/<change-id>/`, moved to `specs/active/` at Gate 1.5 — rule 1). Every child `spec.md` **links its parent epic and lists the inherited invariants** (rule 4); each change's consistency-gate then checks its design against those invariants.
- **Executing.** Each child change runs the **full change flow** — the `CLAUDE.md` diagram, every gate. The epic itself is never coded; it only spawns and tracks changes.
- **Closing / reopening.** The epic becomes `Status: Done` when **every map row reached one of three
  closing destinations**: **archived** (`done → archive/…`, rule 5(f)), **cut with a stated reason**, or **deferred
  with a stated verdict**. Cut and deferred **never graduate to archived** — that is what separates them
  from `pending`, and a map still holding `pending` is not closeable. **Grandfathered:** a row archived
  before rule 5(f) existed may carry a bare `done` (`002-sdd-adoption` C0–C10 — legitimate, not pending).
  The destination is a **protocol token** — the first word of the row's last cell, from the closed set
  listed under "Protocol tokens" (the single source; not restated here). Verification is
  **`tests/check-epic-closing.sh`**, run in CI: it reports each epic it verifies, each it **skips** with the
  reason, and whether it found a fog section — no silence counts as approval. It checks the token is
  present, **never** the quality of a `cut` motive or a `deferred` verdict; that stays human judgement at
  this gate. It **reopens** — `Status:` goes back and a new line is added to the map — when a
  later finding demands a fresh change. Precedent: **`002-sdd-adoption` was reopened after being closed at
  C9** (C10 added a new change), which is normal, not an anomaly.
  **No fog survives closing.** At `Status: Done`, every `## Fog` entry has either graduated to a map row or
  been cut with a stated reason. An epic that closes with open fog is not closed — it is abandoned quietly.

The change-vs-epic **sizing trigger** — when to open an epic instead of a single change — lives in **rule 2** (single owner of sizing — the kind criterion and the alarm of 16); this section does not repeat either.
