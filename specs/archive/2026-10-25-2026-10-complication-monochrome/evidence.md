# Evidence: Complication do AOD em imagem monocromática, na cor do tema do mostrador

Change-ID: 2026-10-complication-monochrome
Status: Complete         <!-- Pending | Complete -->
Verdict: COMPLETE
<!-- Verdict: COMPLETE | INCOMPLETE — the validation-gate writes this. MUST be the first
     `^Verdict:` line; hooks/CI read the VALUE (comment stripped). Never translate the token.
     Keep the comment OFF the value's line: on it, the token inside the comment defeats the read. -->
Cross-model review: indisponível neste ambiente — nenhum segundo modelo (codex/gemini) instalado; o eixo Spec rodou num subagente fresco (opus) que leu só os artefatos e o diff; o eixo Standards num subagente separado (sonnet).

**Resumo do veredito.** R1–R8 implementados e verificados; nada fora da spec no diff; nenhum item de Out of scope implementado; L2 verde no comando da CI e APK de release conferido; revisão visual aprovada em linha válida (tasks 2,3). Decisões para a assinatura: **Ruling 1** (manifesto `ICON,SMALL_IMAGE` em vez do `MONOCHROMATIC_IMAGE,SMALL_IMAGE` do design — grafia que o sistema reconhece; confirmado no Chic e no Gravity); **Ruling 2** (leitura do Gravity na execução da lista, M0); **Ruling 3** (sem teste automatizado do ramo Android); **dispensas** M7 e M14 (Ricardo Nogueira, 2026-10-25); **Risco 4** (nenhum mostrador usa `SMALL_IMAGE`: o lado colorido de R1 e R5 se apoiam em `PresentationTest`, no diff e no APK); **N1** por observação do autor ("instantâneo"), mesmo método da change anterior.

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
| R1 | `app/src/main/AndroidManifest.xml` (`SUPPORTED_TYPES="ICON,SMALL_IMAGE"`, Ruling 1); `AodComplicationService.onComplicationRequest` / `getPreviewData` → `dataFor(type, …)` (`when`: `MONOCHROMATIC_IMAGE`, `SMALL_IMAGE`, `else -> null`; 2a51f79) | Sem teste automatizado do ramo Android (Ruling 3). Lado colorido: `PresentationTest` | M0 (listas dos slots do Chic e do Gravity), M1 (cor do tema; `dumpsys`: `3=MonochromaticImageComplicationData` nos dois mostradores). APK de release: `aapt2 dump xmltree` → `ICON,SMALL_IMAGE`. Lado `SMALL_IMAGE` sem mostrador (Risco 4, M10 n/a): diff (mesmo builder `SmallImageComplicationData`) e tipo declarado no APK | PASS (lado colorido pelo fallback do Risco 4) |
| R2 | `core/MonochromeForm.kt` `monochromeFormOf(On) = SOLID`; `AodImage.monochromeIcon` (SOLID → `R.drawable.aod_text`, sem tint) | `MonochromeFormTest.ligado e solido` | Unit (L2); M2 OK; revisão visual aprovada (task 3) | PASS |
| R3 | `monochromeFormOf(Off) = HOLLOW`; `res/drawable/aod_mono_hollow.xml` (A/D só contorno 2,2 round; relógio a alfa 0,6) | `MonochromeFormTest.desligado e vazado` | Unit; XML contra as Global Constraints; M3 OK; revisão visual aprovada (task 2) | PASS |
| R4 | `monochromeFormOf(Unavailable) = STRUCK`; `res/drawable/aod_mono_struck.xml` (`clip-path` quadro menos a faixa da folga, sentidos opostos; tarja (14,76)–(88,24), 3,6, ponta round) | `MonochromeFormTest.indisponivel por permissao e com tarja`, `…por chave ausente e com tarja` | Unit; geometria do `clip-path` recalculada no gate; M4 OK; revisão visual aprovada | PASS |
| R5 | Ramo `SMALL_IMAGE` de `dataFor` (`SmallImageComplicationData` + `AodImage.icon(presentation)`); `presentationOf` e `aod_text.xml` fora do diff; `icon` delega a `rasterize` com o mesmo drawable e o mesmo SRC_IN | `PresentationTest.ligado e ambar`, `desligado e branco`, `indisponivel e cinza para qualquer motivo` | NO-TASK de preservação. M10/M11 n/a (Risco 4): testes de unidade das cores verdes no L2 e inspeção do diff | PASS (fallback do Risco 4) |
| R6 | Mesmo `aodToggle(this).current()` e mesmo `tapIntentFor(tapActionFor(state))` nos dois tipos; `UPDATE_PERIOD_SECONDS` 300 (APK); `ComplicationTapReceiver` fora do diff | `TapActionTest` (existente); ramo do serviço sem teste (Ruling 3) | M5 OK; M6 OK; M7 dispensado (waiver); período 300 conferido no APK | PASS (M7 dispensado por Ricardo Nogueira em 2026-10-25) |
| R7 | `app/src/test/java/rs/prelude/aodtoggle/core/MonochromeFormTest.kt` | 4 casos: On, Off, `Unavailable(NO_PERMISSION)`, `Unavailable(KEY_MISSING)` | `TEST-…MonochromeFormTest.xml`: `tests="4"`, sem falha; L2 exit 0 | PASS |
| R8 | `docs/manual-checklist.md` § "Complication monocromática" (M0–M14, cobertura) | n/a (lista manual) | Executada em 2026-10-25 no OPWE242; resultados em "Lista manual (R8) — resultados"; M7/M14 dispensados, M10/M11 n/a (Risco 4) | PASS |

## NFR verification
| NFR ID | Target | Measured value | Method / command | Result |
|--------|--------|----------------|------------------|--------|
| N1 | ≤ 1 s do toque até a nova forma (monocromática) | "Está tudo instantâneo" (autor); ~0,2 s de transição visível no `screenrecord` (sem marcação do toque) | M8, observação do autor (mesmo método da change anterior, F8) | PASS (observacional; os três tempos do M8 não foram cronometrados) |
| N2 | No target | — | — | n.a. |
| N3 | n.a. (sem tenant, sem rede) | — | Coberto por N4 | n.a. |
| N4 | Apenas `WRITE_SECURE_SETTINGS` | única `uses-permission: android.permission.WRITE_SECURE_SETTINGS` | `aapt dump permissions app/build/outputs/apk/release/app-release.apk` (2a51f79); M12 OK | PASS |
| N5 | Falha → linha em `AodToggle`; caminho feliz sem log | Feliz: vazio. Revogado: `W AodToggle: AOD indisponivel: sem permissao WRITE_SECURE_SETTINGS` | M9 (`adb logcat -s AodToggle`); o ramo novo não registra | PASS |
| N6 | Sem trabalho novo em segundo plano; 300 s | `dumpsys alarm`: 0 linhas; `dumpsys jobscheduler`: só contabilidade; `UPDATE_PERIOD_SECONDS=300` no APK | M13; `aapt2 dump xmltree`; M14 dispensado | PASS (M14 dispensado por Ricardo Nogueira em 2026-10-25) |

## Scope audit — unspecified additions
<!-- From the inverse walk over the diff. Each item: revert, or human-approved spec amendment. -->

| Arquivo / símbolo | Motivação |
|---|---|
| `AndroidManifest.xml`: `SUPPORTED_TYPES` = `ICON,SMALL_IMAGE` | R1 (Ruling 1) |
| `core/MonochromeForm.kt`: `MonochromeForm`, `monochromeFormOf` | R2–R4, R7 |
| `system/AodImage.kt`: `monochromeIcon`; `private rasterize` (extração; `icon` delega com o mesmo resultado; só a mensagem do `checkNotNull` mudou) | R2–R4 |
| `complication/AodComplicationService.kt`: `dataFor(type, …)` com o tipo decidido num ponto só; `getPreviewData` para os dois tipos | R1, R6 |
| `res/drawable/aod_mono_hollow.xml`, `aod_mono_struck.xml` | R3, R4 |
| `MonochromeFormTest.kt` | R7 |
| `README.md` (monocromática, recolocar a complication, troubleshooting com a tarja) | Risco 3 da spec, R1–R4 |
| `docs/manual-checklist.md` (M0–M14; `<pacote>` na restauração) | R8 |
| `CONTEXT.md` (glossário: imagem monocromática, cor do tema, tarja) | Termos da spec; só documentação |

Sem dependência, endpoint, serviço, alarme ou job novo. **Adições sem motivação: nenhuma.** Rulings que acrescentam comportamento: nenhum (o Ruling 1 muda a grafia do tipo, não o comportamento de R1; diverge do texto do design, não da spec — o SoT registra `ICON,SMALL_IMAGE`).

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

- Tela do gatilho e ícone do app: respeitado — `trigger/` e `res/mipmap-anydpi` fora do diff; o gatilho segue com `AodImage.icon(presentation)`, mesmo resultado.
- Imagem própria para o modo ambiente: respeitado — sem `ambientImage`.
- Outros tipos de complication: respeitado — `dataFor` atende só `SMALL_IMAGE` e `MONOCHROMATIC_IMAGE` (`else -> null`); manifesto `ICON,SMALL_IMAGE`.
- Escolher o tipo por slot ou forçar o colorido: respeitado — o app só declara e responde ao `request.complicationType`.
- Descobrir ou ler a cor do tema: respeitado — imagem em branco puro, sem leitura de cor.
- Mudar a imagem colorida: respeitado — ramo `SMALL_IMAGE` com o mesmo builder; vazado e tarja só nos `aod_mono_*`.

## Regression standing
<!-- Commands run (test suite, lints, build) and exit status. -->

- **L2** no HEAD final 2a51f79, JDK 17, mesmo comando da CI (`.github/workflows/ci.yml`): `./gradlew --no-daemon ktlintCheck detekt lintDebug test assembleRelease` → exit 0, `BUILD SUCCESSFUL`; 28 testes de unidade (debug): AodToggleTest 14, MonochromeFormTest 4, PresentationTest 3, TapActionTest 3, TriggerViewTest 4 (L0: 24). O eixo Spec conferiu o mesmo conjunto em b2d2dff; 2a51f79 só consolida o `when` do serviço (achado Standards), com L1 verde e o debug reinstalado no relógio (Gravity segue com `MonochromaticImageComplicationData`).
- **Artefato montado:** `app-release.apk` — `aapt dump permissions`: só `WRITE_SECURE_SETTINGS`; `aapt2 dump xmltree`: `SUPPORTED_TYPES="ICON,SMALL_IMAGE"`, `UPDATE_PERIOD_SECONDS=300`.
- **Guard que lê token:** n.a. **Comandos operacionais contra infra viva (passo 6):** n.a.; os comandos adb da lista rodaram no relógio real (R8).
- **Passo 7 (visual):** tasks VISUAL 2 e 3; linha `visual-approved` na forma do launcher, id desta change, lista 2,3 — válida.

## Standards (eixo separado — validation-gate passo 8)
<!-- Sem código no diff → `n.a. — <motivo>`. Escopo é o diff da change, não o repo.
     Declare a isolação: subagente separado do eixo Spec, ou a ausência dele.
     Todo achado sai daqui como `fixed` (com ref) ou `accepted by <nome> on <data>` — nunca por omissão.
     Os 12 smells vivem no `validation-gate`; esta seção reporta, não os lista. -->

Isolação: subagente separado do eixo Spec (sonnet), que leu só o diff `16cc065..HEAD -- app README.md` e o passo 8. Sem `CODING_STANDARDS.md`/`CONTRIBUTING.md` no repo: vale a base dos 12 smells.

| Achado | Smell | Onde (file:line do diff) | Por que morde aqui | Desfecho |
|---|---|---|---|---|
| Três `when` sobre `ComplicationType` com o mesmo par de tipos; o de `dataFor` caía no colorido por `else` | Repeated Switches | `AodComplicationService.kt` (`onComplicationRequest`, `getPreviewData`, `dataFor`) | Um tipo novo exigiria três edições; esquecer `dataFor` devolveria o colorido em silêncio | fixed (2a51f79): o tipo é decidido só em `dataFor`, `else -> null` |
| Desenho vazado copiado dentro do `<group>` com clip-path de `aod_mono_struck.xml` | Duplicated Code | `aod_mono_struck.xml` ~l.12–50 vs `aod_mono_hollow.xml` ~l.8–48 | Ajuste só no `hollow` faria o `struck` derivar; VectorDrawable não tem include | accepted by Ricardo Nogueira on 2026-10-25 |
| Ramo Android (`monochromeIcon`, `rasterize`, `dataFor`) sem teste automatizado | observação (fora dos 12) | `AodImage.kt`, `AodComplicationService.kt` | O design declara o relógio como seam (Ruling 3) | accepted by Ricardo Nogueira on 2026-10-25 |

## Deferred / waived items
<!-- DEFERRED NFRs with their homolog/prod runbook; waivers need the human's name and date. -->

| Item | Decisão | Motivo | Quem / quando |
|---|---|---|---|
| M7 (R6, atualização sem toque em ≤ ~5 min) | Dispensado | Mesmo mecanismo da change anterior (`UPDATE_PERIOD_SECONDS=300`, mesmo serviço; o ramo monocromático só muda o desenho), medido lá em 2 min 25 s (`specs/archive/2026-10-25-2026-10-aod-toggle-complication/`). Runbook se quiser medir: relógio fora do cabo, tela ligada no mostrador, `adb shell settings put global ambient_enabled <0|1>`, cronometrar até a forma mudar. | waived by Ricardo Nogueira on 2026-10-25 |
| M14 (N6, `batterystats` ~1 h) | Dispensado | Sem trabalho novo em segundo plano: M13 sem alarme nem job; mesmo período de 300 s; a change anterior mediu ~8 acionamentos/h. Runbook: `adb shell dumpsys batterystats --reset`; ~1 h fora do carregador com a complication monocromática no mostrador ativo; `adb shell dumpsys batterystats \| grep -A30 <pacote>`. | waived by Ricardo Nogueira on 2026-10-25 |

