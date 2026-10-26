# Evidence: Complication do AOD em texto curto (SHORT_TEXT), com o relógio e "AOD"/"OFF"/"---"

Change-ID: 2026-10-complication-short-text
Status: Pending          <!-- Pending | Complete -->
Verdict: —
<!-- Verdict: COMPLETE | INCOMPLETE — the validation-gate writes this. MUST be the first
     `^Verdict:` line; hooks/CI read the VALUE (comment stripped). Never translate the token.
     Keep the comment OFF the value's line: on it, the token inside the comment defeats the read. -->
Cross-model review: —    <!-- model used + agreement summary, or "unavailable in this environment" -->

## Baseline (L0)
<!-- Filled at implementation start (after Gate 1.5 and a green check-tasks, before the first task).
     See task-verify Level 0. -->
Base SHA: 0bbcbda (branch `feat/ricardo/2026-10-complication-short-text`, cortada de `feat/ricardo/2026-10-complication-monochrome` em ca732f3 — a PR vai junto; até 0bbcbda só artefatos de spec, nenhum código)
Reused evidence: —

| Subproject | Command | Result (exit) |
|------------|---------|---------------|
| app (Gradle, JDK 17.0.18-tem) | `./gradlew --no-daemon ktlintCheck detekt lintDebug test assembleRelease` | 0 — `BUILD SUCCESSFUL`; 28 testes de unidade (debug) verdes |

Human decision (if red): n/a — green

## Visual checkpoints
<!-- The visual review of the change: one review per change that has a VISUAL task, held
     after all tasks are DONE and before the validation-gate. The preview comes up by the command of
     the design's Dev-run premise; the human operates it and decides. A change with no VISUAL
     task has no review (write n.a.).
     The approval line under this heading is written ONLY by the human, who types
     `! sdd-approve visual [change-id]`; the agent never writes it nor invokes the launcher
     (instruction — the PR review is the control). Its form, quoted here without the comment
     opening: `visual-approved: change <id> tasks <list> by <who> on <date>`
     (<list> = every task the ledger marks VISUAL). The gate reads the line inside the HTML comment,
     and only a line in the launcher's exact form counts; any other spelling is not an approval.
     A rejection is a ROUND, not an approval: each point of the human's feedback becomes an item
     (same Round number), fixed with a green L1 and the commit noted in the Fix cell; the ledger
     rows stay DONE (no task is reopened) and neither the design nor the ledger changes. The next review covers the whole
     change again.
     When this file is (re)written (e.g. by the validation-gate), CARRY FORWARD every existing
     approval line (both forms, per change and per task) and every round row — regenerating from
     the template without them destroys approvals. -->
Preview: <command of the Dev-run premise used>

| Round | Item (human feedback) | Fix (commit) | L1 |
|-------|-----------------------|--------------|----|

## Requirement walk
| Req ID | Implemented (file/symbol) | Tested (test name) | Verified how | Result |
|--------|---------------------------|--------------------|--------------|--------|

## NFR verification
| NFR ID | Target | Measured value | Method / command | Result |
|--------|--------|----------------|------------------|--------|

## Scope audit — unspecified additions
<!-- From the inverse walk over the diff. Each item: revert, or human-approved spec amendment. -->

## Rulings
<!-- Cada decisão tomada na execução sem o humano (o ledger do SP é apagado no fim; o registro mora aqui).
     Um ruling que acrescenta comportamento fora da spec também é listado no audit de escopo acima.
     Sem rulings, `nenhum`. Ao reescrever este arquivo, carregue adiante os rulings já gravados. -->

| # | Task | Ruling (o quê) | Por quê | Custo se errado |
|---|------|----------------|---------|-----------------|

## Out-of-scope respected
<!-- Confirm each out-of-scope item was not implemented. -->

## Regression standing
<!-- Commands run (test suite, lints, build) and exit status. -->

## Standards (eixo separado — validation-gate passo 8)
<!-- Sem código no diff → `n.a. — <motivo>`. Escopo é o diff da change, não o repo.
     Declare a isolação: subagente separado do eixo Spec, ou a ausência dele.
     Todo achado sai daqui como `fixed` (com ref) ou `accepted by <nome> on <data>` — nunca por omissão.
     Os 12 smells vivem no `validation-gate`; esta seção reporta, não os lista. -->

Isolação: <subagente separado | ausente — motivo>

| Achado | Smell | Onde (file:line do diff) | Por que morde aqui | Desfecho |
|---|---|---|---|---|

## Deferred / waived items
<!-- DEFERRED NFRs with their homolog/prod runbook; waivers need the human's name and date. -->
