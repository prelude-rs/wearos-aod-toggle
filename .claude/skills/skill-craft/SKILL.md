---
name: skill-craft
description: Reference for writing and pruning the kit's skills — the vocabulary that makes a skill predictable, and the kit's own exceptions to it.
disable-model-invocation: true
---

# Skill Craft

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking
the same *process* every run, not producing the same output — is the root virtue; every lever below
serves it.

This skill says whether a skill is **well formed**. To find out whether it *works*, use
`superpowers:writing-skills` — its TDD loop (write the pressure case, watch the agent fail without the
skill, write the skill, watch it pass) is the empirical instrument, and is not restated here.

Lineage: the vocabulary is harvested from [`mattpocock/skills`](https://github.com/mattpocock/skills)
(`writing-great-skills`), per `DESIGN-HISTORY.md` §5 Channel 2. The two kit exceptions at the bottom are
ours.

## Failure modes — each with the test that diagnoses it

Name the failure before fixing it. A pruning pass that cannot name what it is removing is taste, not
discipline.

- **Sprawl** — the skill is simply too long, even when every line is live and unique. *The test:* does
  the agent wade through material it does not need on this path? Cure: push reference down behind a
  pointer, or split by branch.
- **Sediment** — stale layers that settled because adding feels safe and removing feels risky. *The
  test:* is this line still true of the system as it is today? Sediment is the default fate of any skill
  without a pruning discipline.
- **Duplication** — the same meaning in more than one authoritative place. *The test:* to change this
  behaviour, how many files must I edit? More than one means duplication. It costs maintenance and
  tokens, and inflates a meaning's prominence past its real rank.
- **No-op** — a line the model already obeys by default, so you pay load to say nothing. *The test:*
  does this line change behaviour versus the default? This is model-relative: settle a disagreement by
  running the skill, not by debate.
- **Negation** — steering by prohibition backfires: *don't think of an elephant* names the elephant and
  makes it more available. *The test:* is the target behaviour stated positively anywhere? Prefer the
  positive form; keep a prohibition only as a hard guardrail you cannot phrase positively, and pair it
  with what to do instead. **See the kit exception below — this one we deliberately break.**

## Levers, on four axes

### Invocation — who can reach the skill, and what it costs

A **model-invoked** skill keeps its `description`, so the agent can fire it autonomously and other
skills can reach it. It pays **context load**: that description sits in the window every turn, spending
tokens and attention.

A **user-invoked** skill (`disable-model-invocation: true`) strips the description from the agent's
reach — zero context load, but it spends **cognitive load**: the human becomes the index that must
remember it exists. That is not a cost to minimise; it is the price of human agency.

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. When
user-invoked skills multiply past what one person can hold, the cure is a **router skill**: one
user-invoked skill that names the others and when to reach for each.

### Information hierarchy — how far down each piece sits

Three rungs, ranked by how immediately the agent needs the material: **in-skill step** (an ordered
action, the primary tier) → **in-skill reference** (a rule or definition, consulted on demand) →
**external reference** (pushed into a sibling file, reached by a **context pointer**).

**Progressive disclosure** is the move down that ladder. **Branching** is the test for when to make it:
inline what every branch needs, disclose what only some branches reach. A context pointer's *wording*,
not its target, decides when and how reliably the agent reaches the material — so a must-have target
behind a weak pointer is a variance bug, and the fix is the wording.

**Co-location** decides what sits *beside* a piece once it lands: a concept's definition, rules, and
caveats under one heading rather than scattered.

### Steering — shaping runtime behaviour

A **leading word** is a compact concept already in the model's pretraining that the agent thinks with
while running the skill (*seam*, *tracer bullet*, *fog of war*, *encaixe*). Repeated as a token — never
as a restated sentence — it anchors a whole region of behaviour in the fewest tokens, because it
recruits priors the model already holds. Coining your own works only if you define it, and then you pay
in definition tokens what a pretrained word gives free.

A **completion criterion** is the condition that tells the agent a unit of work is done. Two properties
make it a lever: its **clarity** (can the agent tell done from not-done?) resists **premature
completion** — ending a step because attention slipped to *being done*; and its **demand** (how much it
requires) sets **legwork** — the digging the agent does within a step. "Every modified rule accounted
for" drives thorough work where "produce a change list" does not.

### Pruning — keeping it lean

Keep each meaning in a **single source of truth**, so changing the behaviour is a one-place edit. Check
every line for **relevance**: does it still bear on what the skill does? Then hunt no-ops sentence by
sentence, and when one fails the test, delete the whole sentence rather than trim words from it.

## Claims about mechanism carry their proof

Any claim about how a mechanism behaves carries the command that proves it, or an explicit mark that it
is unproven. **Never the word "verified" without the command beside it.**

This is not a style rule. Two consecutive changes of epic 004 shipped a design containing a confident,
false mechanism claim, and the consistency-gate caught both:

- `merge_claudemd` was said to propagate an updated block to existing adopters. It returns
  `skipped-already-present` when the sentinel exists (`adopt.py:504`), so it never does.
- `sdd-adopt` was said to be reachable by nobody but the human. `.claude/commands/sdd-adopt.md:5`
  invokes it by name.

Both read as solid prose. The difference between the rounds that failed and the round that passed was
mechanical: the passing one cited a file and line beside every claim. Write the grep, paste the line.

## What counts as a paragraph

When a ceiling is placed on paragraph length, a **paragraph** is a maximal run of consecutive non-blank
lines whose first line does not begin with a list marker (`-`, `*`, `N.`), `|`, `#`, a fence, `>`, or
`<!--`.

**Lists and tables are governed by co-location, not by the ceiling.** Breaking a bullet list to fit a
character budget fragments a co-located peer-set — the opposite of what co-location asks for. A naive
measurement that counts an unbroken bullet block as one paragraph will point at harmful work: it did, on
this kit, reporting 12 oversized paragraphs where 2 existed.

## The kit's two exceptions

The kit is not a solo senior's repo. It encodes company law for juniors, and two of the rules above bend
for that.

**1. `MANDATORY` / `NEVER` in a description stay.** By the negation test they are prohibition-steering
and should be phrased positively. Here they are **deliberate imposition**: a junior who skips a gate is
the failure the kit exists to prevent, and the imposition is doing work the positive form would not.
The cost is named, not denied — these words do drag the banned behaviour into context. Any change that
converts them owes a criterion proving the invocation trigger did not regress, which needs the TDD loop
named at the top of this skill.

**2. `disable-model-invocation` requires that nothing but the human needs to reach the skill —
including a command wrapper.** A slash-command whose body says "use the skill X" reaches X the same way
another skill would, and a skill without a description cannot be reached that way. `sdd-adopt` looked
eligible (96 words, human-invoked at adoption) and is **not**: its wrapper invokes it by name, so the
flag risks breaking the kit's documented adoption entry point. Neither this kit nor the upstream source
has a precedent for command → user-invoked skill. Treat a new invocation form as unproven until a human
demo says otherwise (the C11 precedent), and prefer pruning the description over removing it.
