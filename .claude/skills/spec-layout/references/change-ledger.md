## Change ledger (chronology)

Part of the `spec-layout` skill — read when appending a ledger row at archive.

`specs/CHANGELOG.md` is an **insert-only** ledger (rows are added, never edited), **newest first**, giving a legible project-evolution timeline. A row is appended at archive (rule 5(e)):

```
| seq | change-id | epic | date (archived) | PR | one-line | archive folder |
```

The `epic` column holds the parent epic-id (e.g. `002-sdd-adoption`), `—` for a standalone change, or
the literal `fast` for a fast-lane change (rule 5(e); see "Via rápida"). It is insert-only like the rest
of the row: existing rows are not rewritten with historical epic values — they carry `—`.

The `PR` column **may repeat the same number across several rows**: a PR can deliver more than one change
(`git-practices` PR point 4), and the ledger stays **one row per change** regardless. A repeated PR number
is the signal that those changes shipped as a batch — not a duplicate row.

It is the **legible view, not the source of order.** Git remains authoritative for chronology — the
true order is `git log --diff-filter=A --date=short -- 'specs/archive/*/spec.md'`, the monotonic PR
numbers, and the `Refs: <change-id>` commit trailers. The ledger carries the PR# and the folder link so
a reader gets the timeline without git archaeology, but on any discrepancy git wins. (This is why the
ledger is separate from `SOURCE-OF-TRUTH.md`: SoT = current state, CHANGELOG = history — see rule 5(b).)
