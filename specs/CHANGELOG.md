# Change Ledger

Insert-only, **newest first** — the legible evolution timeline. A row is appended at archive
(`spec-layout` rule 5(e)). **Git is authoritative for order**, not this file: the true chronology is
`git log --diff-filter=A --date=short -- 'specs/archive/*/spec.md'` + the monotonic PR numbers + the
`Refs: <change-id>` commit trailers. This ledger is the legible view; on any discrepancy, git wins.
`SOURCE-OF-TRUTH.md` holds current state (no history); this file holds history (no state).

| seq | change-id | date | PR | one-line | archive folder |
|-----|-----------|------|----|----------|----------------|
| 6 | 2026-10-complication-monochrome | 2026-10-25 | — | Complication também em imagem monocromática, na cor do tema do mostrador (ligado sólido, desligado vazado, indisponível com tarja); manifesto declara ICON,SMALL_IMAGE | [specs/archive/2026-10-25-2026-10-complication-monochrome/](archive/2026-10-25-2026-10-complication-monochrome/) |
| 5 | 2026-10-ci-gradle-cache | 2026-10-25 | #6 | (via rápida) CI grava o cache do Gradle em push na dev; sem teste duplicado | [specs/archive/2026-10-25-2026-10-ci-gradle-cache/](archive/2026-10-25-2026-10-ci-gradle-cache/) |
| 4 | 2026-10-release-0.1.0 | 2026-10-25 | #4 | (via rápida) Release 0.1.0: fecha o [Unreleased] e ajusta o versionName | [specs/archive/2026-10-25-2026-10-release-0.1.0/](archive/2026-10-25-2026-10-release-0.1.0/) |
| 3 | 2026-10-ci-github-hosted | 2026-10-25 | #3 | (via rápida) CI em runner do GitHub com o L2 do app | [specs/archive/2026-10-25-2026-10-ci-github-hosted/](archive/2026-10-25-2026-10-ci-github-hosted/) |
| 2 | 2026-10-pr-origin-guard | 2026-10-25 | #2 | (via rápida) Guard de origem: PR para main só a partir da dev; título do SoT | [specs/archive/2026-10-25-2026-10-pr-origin-guard/](archive/2026-10-25-2026-10-pr-origin-guard/) |
| 1 | 2026-10-aod-toggle-complication | 2026-10-25 | #1 | Complication e gatilho (app "AOD") que alternam o AOD do OnePlus Watch 3; pacote rs.prelude.aodtoggle | [specs/archive/2026-10-25-2026-10-aod-toggle-complication/](archive/2026-10-25-2026-10-aod-toggle-complication/) |
