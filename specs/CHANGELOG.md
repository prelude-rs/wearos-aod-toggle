# Change Ledger

Insert-only, **newest first** — the legible evolution timeline. A row is appended at archive
(`spec-layout` rule 5(e)). **Git is authoritative for order**, not this file: the true chronology is
`git log --diff-filter=A --date=short -- 'specs/archive/*/spec.md'` + the monotonic PR numbers + the
`Refs: <change-id>` commit trailers. This ledger is the legible view; on any discrepancy, git wins.
`SOURCE-OF-TRUTH.md` holds current state (no history); this file holds history (no state).

| seq | change-id | date | PR | one-line | archive folder |
|-----|-----------|------|----|----------|----------------|
| 1 | 2026-10-aod-toggle-complication | 2026-10-25 | #1 | Complication e gatilho (app "AOD") que alternam o AOD do OnePlus Watch 3; pacote rs.prelude.aodtoggle | [specs/archive/2026-10-25-2026-10-aod-toggle-complication/](archive/2026-10-25-2026-10-aod-toggle-complication/) |
