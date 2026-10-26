# Evidence: Complication do AOD em texto curto (SHORT_TEXT), com o relógio e "AOD"/"OFF"/"---"

Change-ID: 2026-10-complication-short-text
Status: Complete         <!-- Pending | Complete -->
Verdict: COMPLETE
<!-- Verdict: COMPLETE | INCOMPLETE — the validation-gate writes this. MUST be the first
     `^Verdict:` line; hooks/CI read the VALUE (comment stripped). Never translate the token.
     Keep the comment OFF the value's line: on it, the token inside the comment defeats the read. -->
Cross-model review: indisponível neste ambiente — nenhum segundo modelo/CLI instalado; o eixo Spec rodou num subagente fresco (opus), isolado da conversa de implementação; o eixo Standards num subagente separado (sonnet).

**Resumo do veredito.** R1–R8 implementados e verificados; nada fora da spec; nenhum item de Out of scope implementado; L2 verde com as flags da CI; APK de release conferido; revisão visual aprovada (tasks 2,3). Decisões que o autor assinou em 2026-10-25: **Ruling 1** (execução Native a partir da Task 3; só a Task 1 teve revisão por task; a revisão final do branch não achou Critical nem Important); **dispensa do S6** (atualização periódica no texto curto não cronometrada; apoiada no `UPDATE_PERIOD_SECONDS=300` do APK e no mesmo serviço); **R1 no Chic** (`dumpsys` do protótipo com os mesmos tipos + revisão visual do código final); **R5** pelos testes de unidade (S9 n/a); Minors 4–5 da revisão final aceitos.

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
Preview: `./gradlew installDebug` + `adb shell pm grant rs.prelude.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`; complication "AOD Toggle (debug)" recolocada no Gravity e no Chic (relógio via USB, 2026-10-25)

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
| S6 | Dispensado (autor) | Ver "Deferred / waived items". `UPDATE_PERIOD_SECONDS` declarado no APK de release. |
| S7 | OK (observação) | Revisão visual do autor; mesmo método das changes anteriores. |
| S8 | OK | `adb logcat -s AodToggle`: com permissão revogada, `W AodToggle: AOD indisponivel: sem permissao WRITE_SECURE_SETTINGS`; após o `pm grant` e o toque, nenhuma linha nova. |
| S9 | n/a | Nenhum slot do relógio usa a imagem monocromática ou o `SMALL_IMAGE` (Gravity e Chic preferem o texto curto); R5 se apoia em `MonochromeFormTest` e `PresentationTest` (`testDebugUnitTest`). |
| S10 | OK | `aapt dump permissions app-release.apk`: só `WRITE_SECURE_SETTINGS`; `dumpsys alarm`: 0 linhas do pacote; `dumpsys jobscheduler`: nenhum job (só contabilidade). |

## Requirement walk
| Req ID | Implemented (file/symbol) | Tested (test name) | Verified how | Result |
|--------|---------------------------|--------------------|--------------|--------|
| R1 | `AndroidManifest.xml` (`SUPPORTED_TYPES="SHORT_TEXT,ICON,SMALL_IMAGE"`); `AodComplicationService.dataFor` → ramo `SHORT_TEXT`; ramos `MONOCHROMATIC_IMAGE`/`SMALL_IMAGE` mantidos; um só serviço de complication | — (integração com o mostrador) | `aapt2 dump xmltree` do release; S0: Gravity `3=ShortTextComplicationData` (código final), Chic idem no protótipo com os mesmos tipos + revisão visual do código final; uma só "AOD Toggle" no seletor | PASS |
| R2 | `core/ShortTextView.kt` `shortTextViewOf(On) = ("AOD", SOLID)`; `AodImage.clockIcon` → `aod_clock` | `ShortTextViewTest.ligado mostra AOD com icone solido` | Unit (L2); S1 OK | PASS |
| R3 | `shortTextViewOf(Off) = ("OFF", DIM)`; `aod_clock_dim.xml` (alfa 0,6 por caminho) | `ShortTextViewTest.desligado mostra OFF com icone esmaecido` | Unit; S2 OK | PASS |
| R4 | `shortTextViewOf(Unavailable) = ("---", DIM)` | `ShortTextViewTest.indisponivel por permissao …`, `… por chave ausente …` | Unit; S3 OK | PASS |
| R5 | Ramos `MONOCHROMATIC_IMAGE`/`SMALL_IMAGE`, `monochromeIcon`/`icon`, `aod_text`/`aod_mono_*` fora do diff | `MonochromeFormTest` (4), `PresentationTest` (3), verdes | NO-TASK de preservação; S9 n/a (nenhum slot usa esses tipos) → fallback dos testes de unidade + leitura do diff | PASS |
| R6 | Mesmo `state` e `tapIntentFor(tapActionFor(state))` nos três ramos; `UPDATE_PERIOD_SECONDS=300` | `TapActionTest` (existente) | S4 OK; S5 OK (`_id:2043` igual, sem nova escrita); período 300 no APK; S6 dispensado (autor) | PASS |
| R7 | `ShortTextViewTest.kt` | 4 casos (ligado, desligado, indisponível ×2) | XML `tests="4" failures="0"`; L2 verde | PASS |
| R8 | `docs/manual-checklist.md` § "Complication em texto curto" (S0–S10) | — | Resultados em "Lista manual (R8) — resultados"; S6 dispensado, S9 n/a | PASS |

## NFR verification
| NFR ID | Target | Measured value | Method / command | Result |
|--------|--------|----------------|------------------|--------|
| N1 | ≤ 1 s | Dentro do alvo (S7) | Observação no relógio, mesmo método das changes anteriores | PASS |
| N2 | No target | — | — | n.a. |
| N3 | n.a. | — | Coberto por N4 | n.a. |
| N4 | Só `WRITE_SECURE_SETTINGS` | única `uses-permission` | `aapt dump permissions app-release.apk` | PASS |
| N5 | Log só em falha | Indisponível: 1 linha `W AodToggle: …`; feliz: nenhuma | `adb logcat -s AodToggle` (S8) | PASS |
| N6 | Sem trabalho novo; 300 s | `dumpsys alarm`: 0; `jobscheduler`: nenhum job; `UPDATE_PERIOD_SECONDS=300` | S10 + `aapt2 dump xmltree` | PASS |

## Scope audit — unspecified additions
<!-- From the inverse walk over the diff. Each item: revert, or human-approved spec amendment. -->

Cada mudança do diff `ca732f3..HEAD` tem motivação: `ShortTextView.kt` + teste (R2–R4, R7); `aod_clock*.xml` e `AodImage.clockIcon` (R2–R4); ramo `SHORT_TEXT` em `dataFor` e manifesto (R1, R6); README (R1, Risco 1); lista manual (R8); termo "texto curto" no `CONTEXT.md` (glossário da spec). Sem dependência, endpoint ou permissão nova. **Adições sem motivação: nenhuma.** O Ruling 1 muda o processo, não o comportamento.

## Rulings
<!-- Cada decisão tomada na execução sem o humano (o ledger do SP é apagado no fim; o registro mora aqui).
     Um ruling que acrescenta comportamento fora da spec também é listado no audit de escopo acima.
     Sem rulings, `nenhum`. Ao reescrever este arquivo, carregue adiante os rulings já gravados. -->

| # | Task | Ruling (o quê) | Por quê | Custo se errado |
|---|------|----------------|---------|-----------------|
| 1 | 3, 4 | Execução passa de subagent-driven (design, `**Execução:**`) para Native a partir da Task 3: sem revisão de código por task; fica a revisão final do branch inteiro. Só a Task 1 teve revisão por task. | Decisão do autor (Ricardo Nogueira, 2026-10-25): as revisões por task desta change e da anterior só pegaram detalhes. | Um defeito de uma task só aparece na revisão final, com o branch inteiro. |

## Out-of-scope respected
<!-- Confirm each out-of-scope item was not implemented. -->

Respeitado integralmente: sem `RANGED_VALUE`/`GOAL_PROGRESS` (APK: `SHORT_TEXT,ICON,SMALL_IMAGE`; `dataFor` com `else -> null`); imagem monocromática e `SMALL_IMAGE` fora do diff; sem título e só "AOD"/"OFF"/"---"; sem relógio com tarja (indisponível usa `DIM`); sem imagem de ambiente; gatilho e ícone do app fora do diff; cor/fonte/borda/fundo não configurados; um só serviço de complication.

## Regression standing
<!-- Commands run (test suite, lints, build) and exit status. -->

- **L2** em e59af7d, JDK 17, sem `.env`, mesmo comando da CI: `./gradlew --no-daemon ktlintCheck detekt lintDebug test assembleRelease` → exit 0, `BUILD SUCCESSFUL`; 32 testes (L0: 28; +4 de `ShortTextViewTest`), conferidos nos XML: 0 falhas, 0 erros.
- **Artefato montado:** `app-release.apk` — `SUPPORTED_TYPES="SHORT_TEXT,ICON,SMALL_IMAGE"`, `UPDATE_PERIOD_SECONDS=300`, só `WRITE_SECURE_SETTINGS`.
- A lista rodou no debug com o código de 703ad5b; depois só docs mudaram.
- Guarda (passo 5) e runbook (passo 6): n.a. Passo 7: linha `visual-approved` válida (tasks 2,3).

## Standards (eixo separado — validation-gate passo 8)
<!-- Sem código no diff → `n.a. — <motivo>`. Escopo é o diff da change, não o repo.
     Declare a isolação: subagente separado do eixo Spec, ou a ausência dele.
     Todo achado sai daqui como `fixed` (com ref) ou `accepted by <nome> on <data>` — nunca por omissão.
     Os 12 smells vivem no `validation-gate`; esta seção reporta, não os lista. -->

Isolação: subagente separado do eixo Spec (sonnet); sem `CODING_STANDARDS.md`/`CONTRIBUTING.md` no repo — baseline dos 12 smells.

| Achado | Smell | Onde (file:line do diff) | Por que morde aqui | Desfecho |
|---|---|---|---|---|
| Nenhum achado (nomes, duplicação, switches, primitivos, feature envy e testes conferidos no diff de `app/`) | n.a. | n.a. | n.a. | n.a. |

## Deferred / waived items
<!-- DEFERRED NFRs with their homolog/prod runbook; waivers need the human's name and date. -->

| Item | Decisão | Motivo | Quem / quando |
|---|---|---|---|
| S6 (R6, atualização periódica no texto curto em ≤ ~5 min) | Dispensado | Mesmo mecanismo das changes anteriores (`UPDATE_PERIOD_SECONDS=300`, mesmo serviço; o ramo novo só muda o desenho), medido em 2 min 25 s na primeira change. Runbook: relógio fora do cabo, tela ligada no mostrador, mudar o AOD em Configurações, cronometrar até o texto mudar. | waived by Ricardo Nogueira on 2026-10-25 |

