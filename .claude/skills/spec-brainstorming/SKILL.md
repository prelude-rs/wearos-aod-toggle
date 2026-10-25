---
name: spec-brainstorming
description: MANDATORY Socratic interrogation for producing spec.md and design.md before any implementation. Use whenever the user describes a new feature, change, improvement, fix, refactor, or idea — even casually ("we should add...", "I want to...", "vamos criar...", "let's build...") — and whenever Superpowers brainstorming triggers in this repository. Never skip this for anything larger than a single-file trivial fix.
---

# Spec Brainstorming (Socratic, No-Guessing)

This skill produces `spec.md` (the WHAT) and `design.md` (the HOW) for a change folder per `spec-layout` — the folder is born in `specs/proposed/<change-id>/` and the design transcription moves it to `specs/active/` at Gate 1.5 (`spec-layout` rule 1). **This is how senior engineers work: the expensive mistakes are design mistakes, so all the interrogation happens here, before code.** Announce you are using `spec-brainstorming`.

## The Confusion Protocol (non-negotiable)

User input at this stage is **conversation, not requirements**. Specifically:

- NEVER promote a user statement to a requirement without explicit confirmation. Restate it and ask: "Should this be a requirement, a preference, or context?"
- NEVER infer an unstated requirement, default, or constraint. If you would need to assume something to proceed, STOP and ask. Listing assumptions at the end is not a substitute for asking.
- NEVER guess on an architectural decision (storage, tenancy boundary, auth model, API shape, consistency model, failure semantics). If two or more reasonable options exist, present them with trade-offs and let the human choose.
- If you notice yourself writing "presumably", "likely", "I'll assume" — that sentence is a question you owe the human.

## Phase 1 — Interrogate the WHAT

Ask questions **one theme at a time** (don't dump 15 questions at once). Cover, at minimum:

1. **Problem & leverage** (the CEO-review questions): What problem does this solve, for whom? Is this the highest-leverage version of the request — is there a simpler change that captures 80% of the value? What happens if we don't build it?
2. **Domain**: entities, states, invariants touched. For this codebase: which tenant scope (indústria / grupo econômico / distribuidora) does each behavior apply to? **Capture vocabulary inline, as it is resolved — update `CONTEXT.md` in that moment, never in a batch at the end** (`spec-layout` → "Domain glossary" owns the boundary). Two triggers oblige you to stop and settle the word: **conflict** — the human's term contradicts an existing `CONTEXT.md` entry: say so on the spot, and resolve which one is canonical before writing the requirement; **ambiguity** — the term is vague or carries two senses: propose the canonical term and record the rejected synonym in the "avoid" column. A requirement written on an unsettled word costs more to fix in review than the question costs now.
3. **Scope boundary**: what is explicitly OUT of scope? (An empty out-of-scope section means the interrogation is not finished.)
4. **Non-functional requirements**: latency/throughput targets, data volume, consistency, security/isolation expectations, observability. Demand numbers or explicit "no target".
5. **Acceptance**: for each requirement, how would a reviewer verify it? Requirements that can't be verified must be rewritten until they can.

What the repo, the SoT or the epic already answers is not a question: confirm it in your playback, don't ask it.

Then write `spec.md` from the template, `Status: Draft`, and request **Human Gate 1 (design review)**: "Please review spec.md — does this capture what you meant? Pay special attention to Out of Scope and NFRs. To approve, type `! sdd-approve spec <change-id>` at the prompt." Do not proceed until the human has approved — the decision is the human's; you never write `Status: Approved` yourself (see `spec-layout` → "Status field" for the approval doctrine).

## Phase 2 — Interrogate the HOW

Only after spec.md is Approved. Cover: stack choices and why (reference existing decisions in `SOURCE-OF-TRUTH.md` / the epic — do not relitigate settled decisions silently), data modeling, dependencies (new crates/libs need justification), integration points, failure modes, migration/rollout, and how each NFR will be met *by construction or by test*. Same Confusion Protocol applies.

Write `design.md` **with** its `## Decomposição` from the template, `Status: Draft`: the plan is part of the HOW and is approved with it (`spec-layout` → "Status field"). The decomposition is the design's last section — one `### Task N` block per ordered, atomic, test-first task, each with a `**Refs:**` line naming the requirement IDs from spec.md it covers and, when it changes UI surface, a `**Visual:** sim` line. If >16 implementation tasks (the two mandatory closing rows of the ledger are not blocks and don't count), the count is an alarm, not a split order (`spec-layout` rule 2 owns the sizing criterion): either split by kind — several deliverables become an epic's changes — or write the `**Justificativa de dimensionamento:**` line the rule asks for, saying why it is still one deliverable ending in one green state. A requirement whose acceptance is preservation or human verification declares `NO-TASK: <motive>` at the start of its acceptance cell instead of getting a task. Then **run `.claude/hooks/check-tasks.sh <change-dir>` and make it green before asking for Gate 1.5** — it asserts the R*↔task coverage of the blocks, and the design transcription runs it again and refuses on failure. Then immediately invoke the `consistency-gate` skill. Only after the gate passes, request human approval of design.md (Gate 1.5).

## Phase 3 — Ledger and baseline

The plan already exists and is approved inside design.md — there is no plan written after the HOW is approved. Copy `specs/templates/tasks.md` into the change folder (now in `specs/active/<change-id>/` — the design transcription moved it), run `.claude/hooks/check-tasks.sh --ledger <change-dir>` to generate the execution ledger from the design's blocks, and record the L0 baseline (`task-verify` Level 0). From there implementation may run autonomously — no further questions to the human except genuine blockers covered by the Confusion Protocol (the Confusion Protocol governs this interrogation; during execution, an ambiguity the spec and design leave open is a ruling, and one that would change a requirement is a stop — reopen Gate 1), and the single pause of the visual review, held once when all tasks are DONE if the plan has VISUAL tasks (`spec-layout` → "Status field").
