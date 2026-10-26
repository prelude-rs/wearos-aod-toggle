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
<!-- visual-approved: change 2026-10-complication-short-text tasks 2,3 by Ricardo Nogueira on 2026-10-25 -->
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

## Lista manual (R8) — resultados

Execução de `docs/manual-checklist.md` § "Complication em texto curto", em 2026-10-25, no relógio OPWE242 (USB), com o **debug** (`rs.prelude.aodtoggle.debug`, código em 703ad5b; `SUPPORTED_TYPES="SHORT_TEXT,ICON,SMALL_IMAGE"`).

| ID | Resultado | Observação |
|---|---|---|
| S0 | OK | Gravity: `dumpsys` com `3=ShortTextComplicationData` do `rs.prelude.aodtoggle.debug` (código final). Chic: `3=ShortTextComplicationData` do mesmo pacote no protótipo descartável (mesmos tipos declarados; desenho do código final visto pelo autor na revisão visual). Uma só "AOD Toggle" no seletor. |
| S1 | OK | Revisão visual do autor: relógio sólido e "AOD"; após o toque do S5 também. |
| S2 | OK | Revisão visual do autor: relógio esmaecido e "OFF". |
| S3 | OK | `pm revoke` + complication recolocada sem tocar: relógio esmaecido e "---" (autor). |
| S4 | OK | Revisão visual do autor (toques alternam "AOD"/"OFF"). |
| S5 | OK | `pm grant` com chave 1; toque na "---" → "AOD" com relógio sólido (autor); chave segue 1 e nenhuma escrita nova (`dumpsys settings`: `_id:2043` antes e depois). |
| S6 | Dispensa proposta | Ver "Deferred / waived items" (aguarda confirmação do autor no sign-off). `UPDATE_PERIOD_SECONDS` declarado no APK de release. |
| S7 | OK (observação) | Revisão visual do autor; mesmo método das changes anteriores. |
| S8 | OK | `adb logcat -s AodToggle`: com permissão revogada, `W AodToggle: AOD indisponivel: sem permissao WRITE_SECURE_SETTINGS`; após o `pm grant` e o toque, nenhuma linha nova. |
| S9 | n/a | Nenhum slot do relógio usa a imagem monocromática ou o `SMALL_IMAGE` (Gravity e Chic preferem o texto curto); R5 se apoia em `MonochromeFormTest` e `PresentationTest` (`testDebugUnitTest`). |
| S10 | OK | `aapt dump permissions app-release.apk`: só `WRITE_SECURE_SETTINGS`; `dumpsys alarm`: 0 linhas do pacote; `dumpsys jobscheduler`: nenhum job (só contabilidade). |

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
| 1 | 3, 4 | Execução passa de subagent-driven (design, `**Execução:**`) para Native a partir da Task 3: sem revisão de código por task; fica a revisão final do branch inteiro. Tasks 1–2 já tiveram revisão por task (Task 2 sem). | Decisão do autor (Ricardo Nogueira, 2026-10-25): as revisões por task desta change e da anterior só pegaram detalhes. | Um defeito de uma task só aparece na revisão final, com o branch inteiro. |

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

| Item | Decisão | Motivo | Quem / quando |
|---|---|---|---|
| S6 (R6, atualização periódica no texto curto em ≤ ~5 min) | Dispensa proposta | Mesmo mecanismo das changes anteriores (`UPDATE_PERIOD_SECONDS=300`, mesmo serviço; o ramo novo só muda o desenho), medido em 2 min 25 s na primeira change. Runbook: relógio fora do cabo, tela ligada no mostrador, mudar o AOD em Configurações, cronometrar até o texto mudar. | pendente — confirmação de Ricardo Nogueira no sign-off |

