---
name: validation-gate
description: MANDATORY gate after implementation. Run this whenever implementation tasks are complete, whenever the user asks "is it done", "validate", "can we ship", or before any change folder is archived. Never declare a change complete, never open a PR as ready, and never archive a change without this gate's evidence.
---

# Validation Gate (Deliverable ↔ Spec)

This gate runs on **two independent axes** of equal standing. The **Spec axis** (steps 1–7) answers three questions with evidence, not vibes: **Does the implementation address the spec? Does it implement ONLY what was specified? Does it meet the non-functional expectations?** The **Standards axis** (step 8) answers a fourth, which no other gate in the kit asks: **is the code well written?** Report them **separately** — never merge the findings, never rank across axes, never pick "the worst finding overall". A change can pass one and fail the other, and a merged report lets the strong axis mask the weak one. Announce you are using `validation-gate`. The implementation conversation is biased toward approving its own work — counter this:

- Where subagents are available, run this gate in a **fresh subagent** that reads only the artifacts and the diff, not the implementation conversation.
- Where a second model is available (e.g., `codex exec` or another CLI agent installed in this environment), run the requirement walk below independently on it as well and reconcile: agreement is signal, divergence is a finding to investigate, never to silently drop. If no second model is available, note that in evidence.md.

## Procedure

### Eixo Spec — does the deliverable match the spec? (steps 1–7)

**1. Requirement walk.** For every requirement ID in spec.md, fill the evidence table:

`Req ID | Implemented? (file/symbol refs) | Tested? (test name) | Verified how | Result`

Every row needs concrete pointers. "Implemented: yes" without a file reference is an invalid row. A requirement that is implemented but untested is `PARTIAL`, not `PASS`.

**2. Scope audit (the inverse walk).** Diff the change (`git diff` against the base branch). For every changed file / new public symbol / new dependency / new endpoint: which requirement motivates it? Anything unmotivated is scope creep — list it under "Unspecified additions" with a recommendation (revert, or amend spec retroactively with human approval). Drive-by refactors count. Every ruling in `evidence.md` § Rulings that adds behaviour beyond the spec is an unspecified addition.

**3. NFR verification.** For each non-functional requirement, attach the actual evidence: benchmark output, load test numbers, query plans, memory profiles, OTel traces — whatever spec.md's acceptance criterion demands. Run the measurements; do not estimate. If an NFR cannot be measured in this environment, mark it `DEFERRED` with the exact command/runbook for measuring it in homolog/prod, and flag it prominently — DEFERRED items block archive unless the human explicitly waives them.

**4. Out-of-scope respect.** Read spec.md's Out of Scope section. Confirm none of it was implemented. (This is the most commonly violated section.)

**5. Regression standing.** *Verify the real artifact / environment / live infra — not a proxy.* Run `task-verify` at **Level 2** (or **Level 3** if this change promotes to `main`) **in a CI-equivalent environment** (no local `.env`/secrets — local-green ≠ CI-green; see `task-verify` rule 7) and cite its output here — full suite green, lints clean, build clean. **If the change ships a packaged/deployable artifact** (installed/deployed as a built package or image, not run from the source tree), confirm `task-verify`'s **built-artifact level** ran (rule 8) and cite it — an editable install + in-repo tests do **not** prove packaging/path correctness (a real pilot bug shipped a broken wheel that passed editable tests). Do not re-specify the commands; the levels and project-local commands live in `task-verify`. If you cannot run a clean env / build the artifact, say so explicitly and mark `DEFERRED` with the exact command — treat it as unverified, not green.
   **A green suite is not evidence that a guard guards.** If the change touches anything that *reads a token to decide* — a hook, a gate check, a CI condition — a passing suite proves only that the guard accepts; it never proves the guard **rejects**. Two things are required, and the second is the one that gets skipped: **(a)** a case that makes the guard **fail** (feed it the wrong value and require a non-zero exit), and **(b)** that case's fixture must be **the form the real producer emits** — the actual template line, comment and all — not a reduced one you typed by hand. A fixture cleaner than reality tests a shape the system never produces. *(This rule exists because the kit had (a) and not (b): four verdict guards, 27 green assertions, and a bypass in all four — the template puts both tokens in a comment on the value's line, so `grep -w COMPLETE` matched inside the comment and no guard could ever reject. Found by a negative control, never by the suite; `2026-07-verdict-lido-do-valor`.)*

**6. Operational commands verified against live infra.** If the change produces operator-run runbook commands (deploy / cutover / rollback / scheduler / job invocation, e.g. a `docs/` runbook), verify they **resolve against the live project** — resource names, region/location, invocation form — before COMPLETE, or mark `DEFERRED` with the exact verification step. Cite what was checked. *(Same principle as step 5, and the sibling of the "seed/verify from current code" rule: an assumed command is a confidently-wrong anchor — a pilot cutover runbook named a scheduler that didn't exist.)*

**7. Visual review.** If the change's plan has VISUAL tasks — read the `**Visual:** sim`
marks in the `### Task N` blocks of `design.md` (the ledger `tasks.md` only copies them; a change
without `## Decomposição` still carries them in `tasks.md`): (a) when (re)writing
evidence.md, CARRY FORWARD every `visual-approved` line and every round item already present under
"## Visual checkpoints" (read them first and re-insert them verbatim — regenerating from the
template without them destroys human approvals; this is the common path, not an edge case);
(b) verify the change's approval:
ONE line in the launcher's exact form — an HTML comment whose opener is followed by one
space and `visual-approved: change <id> tasks <list> by <who> on <date>`, then the comment's
closer — whose `<id>` is this change's id and whose list contains every VISUAL task.
Only that form counts: a line spelled any other way (no comment opener, no space after it,
another id, text around it) is not an approval — it is itself a finding, because that form is the
one the launcher writes. No such line is
INCOMPLETE — the gap is the visual review (`! sdd-approve visual [change-id]`), not a task.
Per-task lines (`visual-approved: task <N>`) are history: kept, never migrated, and they never
satisfy (b). No VISUAL tasks: record n.a.

### Eixo Standards — is the code well written? (step 8)

**8. Standards.** *Is the code well written?* This step judges internal quality — the band between "lint
passes" and "matches the spec" that no other gate looks at.

**Dispensa:** no code in the diff (prose, template, gate wording, docs) → this step is `n.a.` **with the
reason stated**, not a silent skip. Scope: **the change's diff**, never the whole repo — the axis reviews
what this change wrote, not what it inherited.

**Three rules bind the baseline below:**
   - **The repo's documented standard overrides.** Where a `CODING_STANDARDS.md`, `CONTRIBUTING.md` or
     equivalent exists, it wins over anything here — and a violation of a *documented* standard may be
     reported as hard, unlike a smell.
   - **Every smell is a judgement, never a hard violation.** Name it, say why it bites *here*, propose the
     fix. A smell you cannot justify against this diff is noise; drop it.
   - **Skip what the tooling already enforces.** `task-verify` already runs lint, type-check and build.
     Formatting, import order, unused symbols and type errors are its job — reporting them here is
     duplication.

**Baseline — the 12 smells (Fowler, *Refactoring* ch. 3).** Each: what it is → how to fix.
   1. **Mysterious Name** — a name that doesn't reveal intent → rename until the call site reads as prose.
   2. **Duplicated Code** — the same logic in two places → extract function; if it drifted, unify first.
   3. **Feature Envy** — a function more interested in another object's data than its own → move it there.
   4. **Data Clumps** — the same group of fields travelling together → make them one object.
   5. **Primitive Obsession** — a primitive standing in for a domain concept → introduce the type.
   6. **Repeated Switches** — the same switch/if-chain in several places → polymorphism or a lookup table.
   7. **Shotgun Surgery** — one behaviour change forces edits in many files → gather what changes together.
   8. **Divergent Change** — one module changed for unrelated reasons → split it along those reasons.
   9. **Speculative Generality** — abstraction built for a need the spec doesn't have → inline it, delete it.
   10. **Message Chains** — `a.b().c().d()` walking a structure → ask the first object for what you need.
   11. **Middle Man** — a class that only delegates → cut out the middle man, talk to the target.
   12. **Refused Bequest** — a subclass ignoring most of what it inherits → prefer delegation.

**Isolation.** Run this axis in a **separate subagent** from the Spec axis where subagents are available —
one axis's findings must not anchor the other's. Where they are not available, **say so in `evidence.md`**
(same doctrine as the cross-model note above); a `## Standards` section that is silent about isolation is an
invalid section, not a passing one.

**A Standards finding never sets the verdict by itself.** `COMPLETE`/`INCOMPLETE` stays governed by the Spec
axis (requirements, scope, NFR, regression). But a finding **does** block a silent sign-off: every one
carries a line in `evidence.md` saying **fixed** (with the ref) or **accepted by \<name\> on \<date\>**. No
Standards finding may be closed by omission.

## Output and verdict

Write `specs/active/<change-id>/evidence.md` from the template, **in the team's language** (per `spec-layout` — pt-BR at Sellers; keep `Status`/`Verdict` tokens, R*/N* IDs, and code identifiers neutral), since a human reads it to sign off. Record the verdict as the template's **`Verdict:` header field** — `Verdict: COMPLETE` or `Verdict: INCOMPLETE` as the FIRST `^Verdict:` line (kept at the top, above any prose/examples); `verify-archived-gates.sh` greps it (`grep -m1 '^Verdict:'`) to block archiving an ungated change. `COMPLETE` = all PASS, no unwaived findings **on the Spec axis** (Standards findings never set the verdict — see step 8; they close as fixed or accepted, never by omission); `INCOMPLETE` = list the gap → task mapping to close it. On COMPLETE: tell the human the change is ready for final review and, after their sign-off, perform the archive-and-rewrite procedure from `spec-layout` rule 5. Never set the verdict to COMPLETE as a courtesy — an honest INCOMPLETE is a success of this gate, not a failure of the work. The verdict names the rulings for the sign-off, so the human signs knowing what was decided without them. When (re)writing evidence.md, CARRY FORWARD the `## Rulings` section already present (read it first and re-insert every row verbatim, as with the visual approvals) — regenerating from the template without it destroys the record, because the SP ledger that held it is deleted at the end.
