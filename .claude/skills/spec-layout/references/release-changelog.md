## Changelog de release

Part of the `spec-layout` skill — read when closing a release or writing a release item.

**This section is the single owner of the release changelog rule** — every other surface points here and
does not restate it.

**Two layers.** The change ledger (`specs/CHANGELOG.md`, `spec-layout` → "Change ledger") is the history of the work: one row per
change, free narrative, keyed by `seq`. The **release changelog** is the root **`CHANGELOG.md`**, in
keep-a-changelog form: one sentence per change, grouped by the version that shipped it — what a reader
opens to learn what a release brought. Every adopting repo has both; the adopter's file is seeded from
`specs/templates/CHANGELOG-release.md`.

**Form.** A header that points to the change ledger and to this section; `## [Unreleased]` always at the
top, even when empty; then one `## [x.y.z] - AAAA-MM-DD` per release, newest first. Items sit under
`### Added`, `### Changed`, `### Fixed` or `### Removed` — a keep-a-changelog convention the check does
**not** enforce. What `.claude/hooks/check-release-changelog.sh` reads: the `## [` section headings, each
item as **one line** starting with `- ` and ending in `(seq N, #PR)` — or `(seq N)` when the change had no
PR — and the two labelled lines below. Two labelled header lines: `**Changes de release (sem item):** seq N, …` (or `nenhuma`)
lists the release changes, which carry no item because the section *is* them; and, in a repo whose ledger
predates the file, `**Ledger anterior a este arquivo:** seq ≤ N`, the birth marker, set once when the file
is created and never changed. No keep-a-changelog link footer: a section's body runs to the next `## `.

**The item is written at archive.** Every change that gets a `seq` — epic, standalone or fast lane —
adds its item under `## [Unreleased]` in the same step as its ledger row (rule 5(e)).

**Only the release change closes a section.** In every repo, kit or adopter, the **release change** (a
fast-lane change, in a PR to `dev`) renames `## [Unreleased]` to `## [x.y.z] - <date>` with the version
about to be tagged, recreates an empty `## [Unreleased]` above it, and adds its own `seq` to the release
declaration instead of writing an item. In the kit the same change also bumps the version. A release
change that closes an `Unreleased` with no items writes a one-paragraph note in the section instead, so
the publish step has text to publish. The **promotion `dev → main` only carries**: it closes nothing, and
it is cut from the **release change's merge commit**, not from the tip of `dev` — whatever reached `dev`
afterwards stays in `Unreleased` for the next release, so each promotion carries one release. A
**hotfix enters through `dev`** like any change, followed by a release change and the promotion.

**The check.** `check-release-changelog.sh`, delegated to by `verify-archived-gates.sh` on every PR, fails
when a ledger `seq` is missing from the file or appears twice (outside the release declaration and the
birth marker), when an item has no `(seq N…)`, and when the file is absent in a repo that has a ledger.
With the PR base it also enforces position: a section already closed in the base cannot change; a `seq`
new in this PR sits in `Unreleased` or in a section closed in this PR; the header lines follow the rules
above; and each section closed in the PR matches one release change declared in it. On a PR to `main`,
`Unreleased` must be empty, and a missing `v<versão>` tag for the previous closed section is a **warning**
(publishing is a later human act). A shallow CI checkout that does not fetch tags makes that warning
unreliable, never the failures.

**Release and publish — the human's sequence, after the promotion merges into `main`:**

```
git fetch
sdd-release notas <versão> > <arquivo> && git tag -a --cleanup=verbatim v<versão> origin/main -F <arquivo>
git push origin v<versão>          # in an adopter, THIS push is what deploys
! sdd-release publicar <versão>     # creates the GitHub Release from the section, or replaces its notes
```

`--cleanup=verbatim` keeps the section's `### Added`/`### Changed`/… lines, which git's default cleanup
would strip from the message as comments. The tag convention is **`v<versão>`** in every repo. `sdd-release` (`bin/` at the plugin root, installed
once per machine like `sdd-approve`, which it uses to resolve the plugin) never creates, moves or pushes a
tag: tagging is the human's act, because in the adopters it is the deploy. The agent does not publish.
