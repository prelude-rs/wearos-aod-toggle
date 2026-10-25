## Terminology mapping (for migrating existing repos)

Part of the `spec-layout` skill — read when migrating an existing repo's vocabulary.

Sellers repos arrive with different vocabularies. Map them to the kit's canonical terms when conforming a project — these are the *same concepts*, not parallel systems, so a repo gets ONE cadence model, not two:

| Incoming term (`/team` family, GSD, custom) | Canonical kit term |
|---|---|
| Sprint / wave (the unit with objective + done-criteria) | a **change** (`specs/proposed/<change-id>/` until Gate 1.5, then `specs/active/<change-id>/`) |
| Multi-sprint initiative / roadmap / milestone | an **epic** (`specs/epics/NNN-*.md`) with a decomposition map |
| Sprint backlog / wave task list | the plan: `### Task N` blocks in `design.md`'s `## Decomposição` (`tasks.md` is the ledger derived from them) |
| `docs/team/sprints/SPRINT-NNN.md`, `docs/architecture/wave*-spec.md` | distill into `spec.md` + `SOURCE-OF-TRUTH.md` |
| Sprint close / wave complete | archive + merge (rule 5), carrying over unfinished tasks |

When a repo's existing planning docs are richer than a single change, decompose them: the initiative becomes the epic, each sprint/wave becomes one change folder.
