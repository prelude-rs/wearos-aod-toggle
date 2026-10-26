# Evidence: Complication do AOD em imagem monocromática, na cor do tema do mostrador

Change-ID: 2026-10-complication-monochrome
Status: Pending          <!-- Pending | Complete -->
Verdict: —
<!-- Verdict: COMPLETE | INCOMPLETE — the validation-gate writes this. MUST be the first
     `^Verdict:` line; hooks/CI read the VALUE (comment stripped). Never translate the token.
     Keep the comment OFF the value's line: on it, the token inside the comment defeats the read. -->
Cross-model review: —    <!-- model used + agreement summary, or "unavailable in this environment" -->

## Baseline (L0)
<!-- Filled at implementation start (after Gate 1.5 and a green check-tasks, before the first task).
     See task-verify Level 0. -->
Base SHA: 401bf2b (branch `feat/ricardo/2026-10-complication-monochrome`, cortada de `dev` em 16cc065; até 401bf2b só artefatos de spec, nenhum código)
Reused evidence: —

| Subproject | Command | Result (exit) |
|------------|---------|---------------|
| app (Gradle, JDK 17.0.18-tem) | `./gradlew --no-daemon ktlintCheck detekt lintDebug test assembleRelease` | 0 — `BUILD SUCCESSFUL`; 24 testes de unidade (debug) verdes |

Human decision (if red): n/a — green

## Visual checkpoints
<!-- visual-approved: change 2026-10-complication-monochrome tasks 2,3 by Ricardo Nogueira on 2026-10-25 -->
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
Preview: `./gradlew installDebug` + `adb shell pm grant rs.prelude.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`; complication "AOD Toggle (debug)" recolocada no slot 3 do Chic (relógio via USB, 2026-10-25)

| Round | Item (human feedback) | Fix (commit) | L1 |
|-------|-----------------------|--------------|----|
| 1 | No Chic e no Gravity a complication seguia colorida (âmbar/branca): o mostrador pedia `SMALL_IMAGE`. Causa: o manifesto declarava `MONOCHROMATIC_IMAGE`, string que o sistema ignora; o nome no manifesto é `ICON` (ruling 1). | 6d835d9 | verde (`./gradlew ktlintCheck detekt lintDebug testDebugUnitTest`) |

## Lista manual (R8) — resultados

Execução de `docs/manual-checklist.md` § "Complication monocromática", em 2026-10-25, no relógio OPWE242 (USB), com o **debug** (`rs.prelude.aodtoggle.debug`, código em 6d835d9 = `SUPPORTED_TYPES="ICON,SMALL_IMAGE"`), complication "AOD Toggle (debug)" recolocada no slot 3.

| Campo | Valor |
|---|---|
| Lista de tipos do Chic (`com.oplus.wearos.watchface.zhenmo.style`), slots 1–3 | `GOAL_PROGRESS, RANGED_VALUE, SHORT_TEXT, MONOCHROMATIC_IMAGE, SMALL_IMAGE` |
| Lista de tipos do Gravity (`com.oplus.wearos.watchface.gravity`), slots 1–3 | `GOAL_PROGRESS, RANGED_VALUE, SHORT_TEXT, MONOCHROMATIC_IMAGE, SMALL_IMAGE` (slot 4 `GOAL_PROGRESS`, slot 5 `RANGED_VALUE`) |
| Tipo usado no Chic | `MONOCHROMATIC_IMAGE` (`dumpsys`: `3=MonochromaticImageComplicationData` do `rs.prelude.aodtoggle.debug`) |
| Tipo usado no Gravity | `MONOCHROMATIC_IMAGE` (`dumpsys`: `3=MonochromaticImageComplicationData` do `rs.prelude.aodtoggle.debug`) |
| Mostrador que usa `SMALL_IMAGE` | nenhum — Risco 4: os dois preferem a monocromática; só os mostradores ativos expõem a lista de slots por `dumpsys` |

| ID | Resultado | Observação |
|---|---|---|
| M0 | OK | Listas lidas por adb nos dois mostradores (acima). |
| M1 | OK | Cor do tema no Chic e no Gravity (slot 3), após o conserto da rodada 1 da revisão visual (`ICON`). Os slots 1–3 aceitam a mesma lista de tipos. |
| M2 | OK | Chave 1: arte sólida na cor do tema (observação do autor). |
| M3 | OK | Chave 0: A e D vazados, relógio esmaecido; distinguível do ligado (observação do autor). |
| M4 | OK | `pm revoke`: desligado cortado pela tarja com folga (observação do autor). |
| M5 | OK | Três toques: três escritas do `rs.prelude.aodtoggle.debug` em `ambient_enabled` (`dumpsys settings`, _id 1798→1801), a chave termina em 1 e o interruptor de Configurações > Tela acompanha (autor); a forma alterna. |
| M6 | OK | `pm grant` com chave 1; toque na tarja → sólida, chave inalterada; toque seguinte → vazada, chave 0 (vigia da chave por adb: `21:46:21 0`). |
| M7 | Dispensado (autor) | Ver "Deferred / waived items". Tentativa por `screencap` falhou: com o relógio no cabo, a tela adormecida mostra a tela de carga, não o mostrador. |
| M8 | OK (observação) | "Está tudo instantâneo" (autor) — mesmo método da change anterior (F8). Gravação `screenrecord` feita, mas sem marcação do toque; onde a troca aparece, completa-se em ~0,2 s. |
| M9 | OK | `adb logcat -s AodToggle` vazio durante os toques com permissão; com permissão revogada: `W AodToggle: AOD indisponivel: sem permissao WRITE_SECURE_SETTINGS`. |
| M10 | n/a | Sem mostrador com `SMALL_IMAGE` (Risco 4); R5 se apoia em `PresentationTest` (`testDebugUnitTest`). |
| M11 | n/a | Idem M10. |
| M12 | OK | `aapt dump permissions app-release.apk`: só `android.permission.WRITE_SECURE_SETTINGS`; `aapt2 dump xmltree`: `SUPPORTED_TYPES="ICON,SMALL_IMAGE"`. |
| M13 | OK | `dumpsys alarm`: 0 linhas do pacote; `dumpsys jobscheduler`: 2 linhas, ambas contabilidade (cota `ShrinkableDebits` e mapa de uid), nenhum job. |
| M14 | Dispensado (autor) | Ver "Deferred / waived items". |

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
| 1 | 3 | O manifesto declara `SUPPORTED_TYPES="ICON,SMALL_IMAGE"`, e não `MONOCHROMATIC_IMAGE,SMALL_IMAGE` como o design escreveu. `ICON` é o nome do tipo `MONOCHROMATIC_IMAGE` no manifesto; o requisito (R1) não muda. | Na revisão visual (2026-10-25) o Chic pedia `SMALL_IMAGE` com os dois tipos declarados, e com só `MONOCHROMATIC_IMAGE` o provedor nem aparecia no slot: o sistema ignora a string `MONOCHROMATIC_IMAGE`. Os provedores da OnePlus (`HeyHealthService.apk`) declaram `…,ICON`. Com `ICON,SMALL_IMAGE` o `dumpsys` do Chic mostra `3=MonochromaticImageComplicationData` do `rs.prelude.aodtoggle.debug`. | Nenhum provável: confirmado no relógio. Se algum sistema aceitar só o nome novo, a complication cai no `SMALL_IMAGE` (colorida), sem sumir. |
| 2 | 4 | A leitura da ordem de tipos do Gravity é passo de execução da lista (M0), não da Task 4. Lida em 2026-10-25: slots 1–3 `GOAL_PROGRESS, RANGED_VALUE, SHORT_TEXT, MONOCHROMATIC_IMAGE, SMALL_IMAGE`. | A Task 4 escreve a lista; R8 a executa. | Nenhum: a leitura acontece antes do validation-gate. |
| 3 | 3 | Sem teste automatizado do ramo Android do serviço (Minor da revisão). | O design declara o relógio como seam; teste exigiria dependência nova (Robolectric), o que fere as Global Constraints. | Uma regressão no ramo monocromático só aparece no relógio. |

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
| M7 (R6, atualização sem toque em ≤ ~5 min) | Dispensado | Mesmo mecanismo da change anterior (`UPDATE_PERIOD_SECONDS=300`, mesmo serviço; o ramo monocromático só muda o desenho), medido lá em 2 min 25 s (`specs/archive/2026-10-25-2026-10-aod-toggle-complication/`). Runbook se quiser medir: relógio fora do cabo, tela ligada no mostrador, `adb shell settings put global ambient_enabled <0|1>`, cronometrar até a forma mudar. | waived by Ricardo Nogueira on 2026-10-25 |
| M14 (N6, `batterystats` ~1 h) | Dispensado | Sem trabalho novo em segundo plano: M13 sem alarme nem job; mesmo período de 300 s; a change anterior mediu ~8 acionamentos/h. Runbook: `adb shell dumpsys batterystats --reset`; ~1 h fora do carregador com a complication monocromática no mostrador ativo; `adb shell dumpsys batterystats \| grep -A30 <pacote>`. | waived by Ricardo Nogueira on 2026-10-25 |

