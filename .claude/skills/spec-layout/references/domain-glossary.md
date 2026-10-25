## Domain glossary (`CONTEXT.md`)

Part of the `spec-layout` skill — read when capturing a domain term.

The project's domain vocabulary lives in **`CONTEXT.md` at the repo root** — not under `specs/`: it is the
*project's* glossary, not an artifact the SDD flow produces or consumes, and the root is where a new human
looks first.

**Boundary — glossary only.** A term, its definition, and the synonyms to avoid. **No** implementation
detail, **no** system state, **no** architecture, **no** decision, **no** scratch pad. State lives in
`SOURCE-OF-TRUTH.md` (rule 5), history in `CHANGELOG.md`, reasons in `docs/adr/`. A `CONTEXT.md` entry that
explains *how* something works has crossed the boundary and belongs in the SoT.

**Lazy creation.** The file is born when the first term is resolved, never before — an empty glossary
teaches nothing. Kit-internal vocabulary (`encaixe`, `seam`, `via rápida`) stays in "Language & rendering
conventions" and is **pointed to**, never copied.

**ADRs — the reasons.** A decision that is neither state nor history lives in **`docs/adr/NNNN-<slug>.md`**,
4-digit monotonic numbering, never reused. The three-criteria test for *when* a decision earns an ADR lives
in `specs/templates/adr.md` and is not restated here.
