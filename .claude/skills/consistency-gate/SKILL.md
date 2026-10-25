---
name: consistency-gate
description: MANDATORY gate before design approval. Run this whenever a design.md (HOW + `## Decomposição`) reaches Draft status, whenever the user asks to "check the spec", "validate the design", "find contradictions", and always before Gate 1.5 — which approves the HOW and the plan together. Also rerun it whenever spec.md or design.md is edited after initial approval. Never let a design reach Gate 1.5 without this gate's report.
---

# Consistency Gate (Spec ↔ Design ↔ Epic)

Adversarial review: your job in this gate is to **find problems, not to confirm the design**. Run it as if a hostile staff engineer were reviewing someone else's work. Announce you are using `consistency-gate`. Where available, run this gate in a fresh subagent that has NOT seen the brainstorming conversation — it must judge only what is written in the artifacts, because juniors and future agents will only have what is written.

## Checks (all mandatory, in order)

**1. Coverage, spec → design.** For every requirement ID in spec.md (functional and non-functional): does design.md contain a design element that satisfies it? Walk every ID, but write down only the gaps — a requirement with no satisfying element is a finding; covered requirements are not listed (the design's own map already says where each one lands). An NFR "covered" by silence is NOT covered — it needs a mechanism (e.g., "p99 < 200ms" needs the design to say what makes that plausible).

**2. Coverage, design → spec.** For every component, dependency, endpoint, or schema element in design.md: which requirement motivates it? Walk every element, but write down only the gaps — an element with no motivating requirement is a finding: either scope creep (conserto: remove it) or a missing requirement (conserto: amend the spec). Be suspicious of "while we're at it" elements.

**3. Contradictions.** Hunt for: design choices that violate an explicit requirement; two design statements that can't both be true; design statements that contradict `SOURCE-OF-TRUTH.md` or settled decisions in the parent epic; quantities that don't add up (timeouts, limits, retention, quota math).

**4. Epic invariants.** Read the parent epic's Invariants section. For each invariant, work out how this design preserves it; an invariant you cannot see preserved is a finding. For this codebase the recurring ones are tenant isolation (no data path may bypass tenant scoping), authn/z on every consumer surface, and observability coverage. "Not applicable" requires a one-line justification — without one, that is a finding. A change with no parent epic reads `n.a. — <motivo>`.

**5. Unstated assumptions.** Find every assumption the design makes that spec.md does not state; each one is a finding. Its conserto sends it back to the human as a question or writes it into spec.md explicitly — assumptions may not live only in the design.

**6. Verifiability.** For each requirement: is the acceptance criterion testable as written? Will `validation-gate` be able to check it mechanically or by inspection? If not, propose rewording now.

**6b. Fronteira do aceite (where-inside).** For every acceptance cell: does it name where-inside
(file:line, symbol, literal command that reaches internals)? The alarm's `AVISO` lines (from
`check-tasks.sh`) are the starting list — judge each one; ignore the `AVISO <change> [dimensionamento]`
lines, which belong to 6c, and also the `AVISO <pasta> [sot]` lines, which are the SoT declaration
(spec-layout rule 5(b)), not the acceptance boundary. Judge `comando` with this rule: a public
verification command is observation, not where-inside — closed default list: `pnpm`, `npm`, `yarn`,
`go test`, `go vet`, `mvn`, `gradle`, `pytest`, `python3 -m pytest`, `make`, `cargo`, `ruff`, `eslint`,
`tsc`, `bash tests/…` — plus the repo's `task-verify` command list when filled; anything else (a
command that reaches the internal, e.g. `grep` on a file line, `git diff`) is where-inside. For each
where-inside finding, propose the rewrite in terms of what a reviewer observes.

**6c. Dimensionamento (sizing).** When the design's `## Decomposição` has more than 16 blocks and
carries the `**Justificativa de dimensionamento:**` line (its `AVISO <change> [dimensionamento] …`
line from `check-tasks.sh` flags it), read the justification against the per-kind criterion of
`spec-layout` rule 2 (the single owner — not restated here). A justification that describes
more than one deliverable or more than one final green state is a finding — the work is another kind.
The check only asserts presence; merit is judged here and by the human at Gate 1.5. A
justification that fails the criterion goes in the report's `## Check 6c` section as a finding; one
that holds reads `sem achados`; with ≤16 blocks or no justification, the section reads
`n.a. — <motivo>`.

**7. Dev-run premise (UI changes).** If the design ships a runnable deliverable with UI (or the
spec carries UI requirements), the design's "Dev-run premise" section MUST exist with a Launch
command and a Mock/dev-flag strategy covering every named external dependency — absence or
empty fields is a BLOCKING finding (FAIL). The launch command must not depend on anything
exclusive to the agent's session. A filled "Signed exception" (reason + name + date) is a
warning the human acknowledges at Gate 1.5 — any other form of exception is a FAIL: the valve
exists only signed at the design gate, never decided mid-implementation.

**8. Seams sob teste.** Read the design's `## Seams sob teste` section.
   - **If the change ships testable surface:** every functional `R*` that touches that surface must map to
     at least one named seam; every **new** seam must carry its justification line; and no seam may observe
     through a **side channel** (e.g. reading the database to check a result instead of using the module's
     interface). A missing seam for a functional requirement is a BLOCKING finding (FAIL).
   - **If the change ships no testable surface** (prose, template, gate wording): the section reads
     `N/A — <reason>` and this check is **`n.a.` with that reason stated** — not a silent skip.
   - Judge the *choice*, not just the presence: a seam that satisfies the three rules in the template
     needs no comment; one that violates them is a finding even when the table is filled.

## Recurring hazards to probe

These have bitten real changes — check them whenever relevant, even if no requirement names them:

- **Data-representation stability.** When a change relies on hashing, keys, dedup, or equality over typed data, verify the canonical representation is **exact and stable across sources**. Large integer ids / codes (>2⁵³) silently corrupt if they pass through `float64`; the "same" value read from two stores (DB vs file) can serialize differently (Decimal vs float, tz-aware vs naive timestamps, trailing zeros). A passing fixture test does NOT prove the invariant — demand a cross-source equality test and exact-precision test for id/key columns.
- **Config-driven, not hardcoded.** If a correctness rule depends on a list of columns/fields/keys, is that list driven by the per-project/per-tenant config, or hardcoded? A hardcoded list silently breaks "new project/tenant = config only."

## Rodadas: o que cada uma julga e quando parar

This section is the **single owner of what a round judges and of when the rounds stop** — other
surfaces point here and do not restate it. The report's form
for these rules (the `Base` column and the stop decision line) is in "Output" below.

- **Round 1 judges everything.** Every check above, over the whole spec/design pair.
- **From round 2 on, a round judges the delta.** It judges the spec and design delta since its base
  (the commit in its `Base` cell, e.g. `git diff <base> -- spec.md design.md` in the change's folder)
  and whether each finding of the previous round was closed — read those findings in the existing
  report before rewriting it. It does not hunt again through text the
  delta did not touch.
- **A new finding outside the delta is `BLOCKING` only in two classes:** (a) it makes a guard or a check allow what it denies today; (b) it leaves a requirement with no design element that satisfies it. Any other new finding outside the delta is a `WARNING`.
- **Stop after the third `FAIL` round.** When a round is the report's third `FAIL` (counted in total,
  not in a row), do not dispatch another round. Stop and take to the human:
  - the cost so far — the rounds and the Gate 1 reopenings (the `## Rodadas` table);
  - the causes of the `BLOCKING` findings — what kind of defect kept producing them, round after round;
  - the options: continue with a ceiling (how many more rounds), cut the scope, reopen Gate 1, split the change, or abandon it.

  Only the recorded decision authorizes the next round: the human decides, and the agent transcribes
  the decision as the stop decision line under the table ("Output"). When its ceiling runs out, stop
  again and ask for a new decision. `check-report.sh` fails a round past what the last decision
  authorizes, and a round after the third `FAIL` with no decision at all.

## Superfície heurística

A **heuristic surface (superfície heurística)** — the glossary term in `CONTEXT.md` — is the part of a
hook or check that classifies free text by pattern: the Bash command in a guard, the judgement of a
path, the regex of a form check. No list of its forms is ever complete. This section is the **single
owner of the rules for a change that alters a heuristic surface** — the spec and design templates point
here; the spec template carries the direction rule in one line, as R4 requires, and the rules live here.

- **The spec declares the classes of forms.** The spec states the heuristic surface's contract by class
  of forms — what each class allows and what it denies — and names the classes the measurement corpus
  must cover. The list of forms lives in the test, never in the spec.
- **The design brings measured code, before Gate 1.5.** The design carries the heuristic surface's code
  already prototyped (code, not prose describing it) and its measurement against the corpus:
  base × prototype, with the expected verdict of each form. The corpus holds the spec's classes, real forms harvested from transcripts or the guards' log, and the commands the change itself needs to run.
- **The gate judges the measurement, not the edges.** The gate judges whether a class is missing from
  the corpus; it may add forms to the corpus and run the measurement again. It does not hunt edges by reasoning.
- **A new edge is judged by its direction.** When any reviewer — this gate, a task review, the final
  review, `validation-gate` — finds a form the list does not have, and the form falls in a declared
  class:
  - the code **allows what the class denies** → `BLOCKING`; the fix is a test case plus the code;
  - the code **denies what the class allows** → `WARNING`, recorded in the parent epic's Fog;
  - in neither case does Gate 1 reopen. Only a new class reopens Gate 1.

## Output

This section is the **single owner of the report's form** — the template, `spec-layout`, the SoT and
`CONTEXT.md` point here and do not restate it. Write the report to
`consistency-report.md` in the change's folder — `specs/proposed/<change-id>/` before Gate 1.5, or the folder in `active/` where a re-run after it finds the change (`spec-layout` rule 1) from `specs/templates/consistency-report.md` (in the
team's language per `spec-layout` — pt-BR at Sellers; keep IDs/identifiers and protocol tokens neutral).

- **One round per file.** A round is one run of this gate over the spec/design pair. On each run,
  rewrite the whole file on every round, holding only the current round: every check section, the
  minimal edit set and the verdict describe this run alone. What an earlier run found lives on only as
  its count line (next item) — its findings and wording are gone from the body.
- **`## Rodadas`.** On each run, append one row to `## Rodadas` and never delete or edit an earlier row.
  A row carries the round's number, verdict, `BLOCKING` count, `WARNING` count, reopenings (Gate 1
  reopening items proposed in that round) and base, in that column order. The table is the measure of
  the change's cost in cycles. The rounds are the consecutive lines of one table, numbered 1..n: row k carries `#` exactly `k`
  and its verdict is exactly `PASS` or `FAIL`, with at least one data row. A new row goes
  directly under the last row, above any decision line; the table ends at the first line that is not
  a table line, and a table line after that fails (`linha de rodada fora da tabela`).
- **`Base` column.** The 6th header cell of the `## Rodadas` table is exactly `Base`.
  From round 2 on, a row's `Base` is the commit at which the spec and design judged by the previous round stood — 7 to 40 lowercase hex characters —
  so the spec and design are committed before every round, and each round names what it judged against.
  Round 1 has no base and writes `—`. What a round judges from its base is in "Rodadas: o que cada uma
  julga e quando parar" below. A report archived in a folder dated on or before 2026-10-14 (the hook's
  cutoff) is read in the earlier form, without the `Base` column.
- **Stop decision line.** After the third `FAIL` round, every later round needs a human decision
  recorded in the `## Rodadas` section, under the table, before that round runs, one line per decision,
  in the exact form
  `- Parada após a rodada <N>: <quem>, <AAAA-MM-DD> — <opção> — teto +<K>` — `<N>` the round after
  which the human decided, `<quem>` who decided, `<opção>` the option chosen, `<K>` how many more
  rounds it authorizes (the ceiling); `<N>` and `<K>` are positive integers. Counting the ceiling: let
  f3 be the round of the third `FAIL` (counted in total, not in a row); a round r after f3 is governed
  by the last decision before it — the greatest `<N>` with f3 ≤ N < r — and is valid only if
  r ≤ N + K. A new decision replaces the previous ceiling, never adds to it, and a decision written
  before the third `FAIL` (N < f3) authorizes nothing. The agent transcribes the human's decision; the
  line is not an approval and carries no approval marker. When to stop and what to take to the human:
  "Rodadas: o que cada uma julga e quando parar" below.
- **Verdict.** Record it as the `Verdict:` header field — a line `Verdict: PASS` or `Verdict: FAIL`
  that is the FIRST `^Verdict:` line in the file (a hook/CI greps `grep -m1 '^Verdict:'`; keep it at the
  top, above any body or quoted examples; never translate the `PASS`/`FAIL` token). The value is
  derived, never argued: `PASS` if and only if the current round has no `BLOCKING` finding; otherwise
  `FAIL`.
- **Check sections.** One heading per check (1, 2, 3, 4, 5, 6, 6b, 6c, 7, 8), always in that order. Each
  body is exactly one of: `sem achados` (the check ran and found nothing); `n.a. — <motivo>` (the check
  does not apply; the reason is mandatory); or a findings table. Checks 1 and 2 record only the gaps —
  never a full requirement-to-element coverage map.
- **Finding (achado).** One table row with five columns, in this order:
  `# | Classe | Sítio | Por que morde aqui | Conserto` — an id (`B1`, `W1`, …), the class, the site
  (`file:line` or section), why it bites here, and the proposed fix.
  Its class is exactly `BLOCKING` or `WARNING`, as plain text (no bold, no other word): `BLOCKING` must be closed before `PASS`; `WARNING` is
  acknowledged by the human at Gate 1.5 (design approval).
- **Findings only — no narrative.** No reasoning trail, no walkthrough of what was checked and held, no
  per-check commentary, no closing argument for the verdict. If a sentence is not a site, a cause or a
  fix, it does not go in the report.
- **Size.** The labeled line `**Justificativa de tamanho:**` is required above 100 lines outside HTML comments:
  `**Justificativa de tamanho:** <motivo>`, under the `Verdict:` line as in the template, saying why the
  report is that long. A value that is empty, blank, a whole `<…>` placeholder, or one of
  `[SPECIFY]`, `TODO`, `N/A` (case-insensitive) counts as empty. At or under 100 lines the line may stay as the template
  placeholder.
- **Mechanical aferição.** `.claude/hooks/check-report.sh <dir>` checks the form (a whole line
  `## Rodadas`), that every finding row's class is exactly `BLOCKING` or `WARNING`, the verdict against
  the round's `BLOCKING` findings, the size justification, the `Base` column with its form from round
  2 on, the form of every round row and decision line, and the stop ceiling; the
  design transcription runs it, so a report that fails it blocks Gate 1.5. The judgment of each finding
  stays here.

**Minimal edit set (on FAIL).** Aim at the design by default — most findings are closed by editing
`design.md`, one line per edit under `### Edições no design`. A **spec edit is the exception**: it is a
**Gate 1 reopening**, listed under its own subsection `### Reabertura do Gate 1`, one line per item in
the form `- <R*|Premissa N|I*> — motivo: CONTRADICTION|UNVERIFIABLE|OVERSPECIFIED — <texto>` — the motive
MUST be one of that closed list (`CONTRADICTION`, `UNVERIFIABLE`, `OVERSPECIFIED`); wording, style, and
"align to the design" are never motives. A new form inside a class the spec declares is never a `CONTRADICTION`: it is judged by its direction
("Superfície heurística" above) and reopens nothing — only a new class does. An `OVERSPECIFIED` item cites the flagged excerpt in backticks
and `→` the rewrite the reviewer should see instead — without that pairing the check rejects it (an
unpaired `OVERSPECIFIED` is wording in disguise). The subsection closes with the counter line
`Reaberturas do Gate 1 propostas: <n>`, matching the number of items listed. Apply none of these edits
silently — present them to the human; every item requires human re-transcription of the approval.

A round 1 that finds zero issues on a non-trivial change is suspicious — look again at checks 2 and 5
before reporting PASS. Rounds 2 and later follow the delta rule above and do not hunt outside it.
