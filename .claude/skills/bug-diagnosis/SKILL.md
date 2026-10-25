---
name: bug-diagnosis
description: MANDATORY before diagnosing any bug — build the red loop first. Use when something is broken, failing, slow, intermittent, flaky, or regressed; when the human says "está quebrado", "não funciona", "está lento", "intermitente", "regrediu".
---

# Bug Diagnosis (the red loop before the hypothesis)

**Posture is not this skill's job.** The discipline of finding the cause before writing a fix belongs to
`superpowers:systematic-debugging`; read it and follow it. **This skill is the instrument** — how to obtain
the signal that makes that discipline possible. Announce you are using `bug-diagnosis`.

## The gate — no red-capable command, no hypothesis

**Before any hypothesis exists, a command exists.** One named command, **already run at least once**, with
its **invocation and output pasted** into the change artifact. Not "a test we could write" — a command that
ran.

It must be all four:

- **red-capable** — it drives the bug's code path **and asserts the exact symptom the human reported**.
- **determinístico** — same input, same verdict. (Non-deterministic bug? See "Reproduction rate".)
- **rápido** — fast enough to run dozens of times without thinking about it.
- runnable by the agent, **sem humano** in the middle.

**`"roda sem erro"` is not red-capable.** A command that passes today observes nothing: it cannot tell you
when the bug is gone, because it never told you the bug was there. If you cannot make it fail on demand, you
do not have a loop — you have a wish.

Build the loop and the bug is most of the way solved. Skip it and no amount of code reading substitutes: you
will be ranking guesses against each other with no way to settle them.

## The ladder — cheapest rung that reaches the bug wins

Climb only as far as you must. Each rung costs more to build than the one above it.

1. **Failing test at an existing seam** — the public boundary that already observes the behaviour (see
   `spec-layout` → "Domain glossary" and the seam sense it declares). Cheapest and most durable: it survives
   as the regression test.
2. **HTTP script** — `curl`/`httpie` against a running instance, asserting the response that is wrong.
3. **CLI invocation with a fixture** — the real entrypoint plus the smallest input that triggers it.
4. **Headless browser** — when the symptom only exists after the page renders or a script runs.
5. **Captured-trace replay** — record the real request/event once, replay it offline as many times as needed.
6. **Throwaway harness** — a scratch script that wires just enough of the system to reach the code path.
7. **Property / fuzz loop** — when you know the invariant but not the input that breaks it.
8. **Bisection harness** — when it worked before: a command that answers pass/fail per commit, then
   `git bisect run`.
9. **Differential loop** — run two versions (or two configs) on the same input and diff the outputs; the
   first divergence is the lead.
10. **HITL script** — a human performs one step the agent cannot. **Last resort**: it breaks
    `sem humano`, so every run costs a person's attention. Describe the steps precisely and keep the human's
    part to a single action.

## Reproduction rate — the target for a non-deterministic bug

A flaky bug does not need a clean repro. It needs a **rate you can move**. **50% is debuggable; 1% is not** —
so the first job is not "make it deterministic", it is "make it frequent".

Levers, cheapest first: **repeat the trigger** in a loop; **parallelise** it; **stress** the machine (load,
memory, slow disk); **narrow the timing window** the race needs; **inject a sleep** at the suspected
interleaving point. Report the rate before and after — a lever that does not move the rate is telling you the
mechanism is elsewhere.

## Hypotheses — 3 to 5, ranked, falsifiable, before testing any

Generate **three to five** hypotheses and rank them **before** testing the first one. Each carries a
prediction in this shape:

> **If X is the cause, then changing Y makes the bug disappear.**

**A hypothesis without a prediction is a guess** — discard it or sharpen it until it predicts something.
Then **show the ranked list to the human before testing**, so a cheap correction can happen before you spend
the expensive step. If the human is absent, proceed — do not block.

Then test one at a time, changing one variable per test.

> **This overrides the Superpowers posture skill on hypothesis count, and this paragraph is the whole rule** —
> nothing else needs to be read to comply. The kit's own repo additionally writes out the reconciliation in its
> encaixe mapping (kit-local, not installed into adopted repos — see the manifest entry). Generating one
> hypothesis at a time is the failure mode this section exists to prevent: the first idea anchors the
> investigation, and the alternatives that were never written down never get tested.

## The regression test comes before the fix

Write the regression test **before** the fix — **provided a correct seam exists**: one that exercises the
bug's real pattern at the call site, not a shallow boundary that happens to be easy to reach.

**If the only available seam is too shallow, that is the finding.** Record it — the missing seam is a real
structural gap and belongs in the change artifact. Do not fake coverage at the wrong boundary: a green test
at a shallow seam is worse than no test, because it claims protection that does not exist.

## Which lane a bug runs in

- **Trivial bug** (cause obvious, one-line fix): **via rápida**, as today. The gate above does not apply —
  there is no diagnosis to do.
- **Hard bug, cause already known:** **via rápida**, and the red loop is what the `change.md` cites as
  verification — the command that went green is the proof of the fix.
- **Hard bug, cause unknown:** **the diagnosis runs first, as its own cycle**, governed by this skill. It
  produces the loop, the ranked hypotheses and the confirmed cause. **Only then** does the fix choose its
  lane by size: trivial → via rápida; structural → the formal flow, where `spec.md` now has the WHAT it was
  missing, because the cause is known.

A bug discovered **during** a change's autonomous execution is not this skill's entry point: that is the
**Confusion Protocol** (blocker → human), which stays the only sanctioned interruption.
