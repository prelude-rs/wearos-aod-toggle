# Evidence: Complication e gatilho para alternar o AOD no OnePlus Watch 3

Change-ID: 2026-10-aod-toggle-complication
Status: Complete          <!-- Pending | Complete -->
Verdict: COMPLETE
<!-- Verdict: COMPLETE | INCOMPLETE — the validation-gate writes this. MUST be the first
     `^Verdict:` line; hooks/CI read the VALUE (comment stripped). Never translate the token.
     Keep the comment OFF the value's line: on it, the token inside the comment defeats the read. -->
Cross-model review: indisponível neste ambiente (sem codex/gemini instalados)

**Resumo do gate (eixo Spec, passos 1–7; 2026-10-25, revisor novo, sobre `git diff e53f3e0 HEAD`, HEAD `0e41891`).**
Todos os R1–R12 e N1–N7 com evidência: PASS (N2/N3 sem meta / n.a.; N8 retirado). L2 verde com JDK 17 e
APK de release assinado `O=prelude-rs`. A revisão visual cobre todas as tasks VISUAL. O veredito COMPLETE
**depende de o sign-off confirmar explicitamente** os itens de "Deferred / waived items" abaixo — em
especial o ruling **R25** (janela de 25 min na fase 2 de N6, contra "~1 h" da spec) e o método de **N1**
(observação do autor, sem os tempos que a lista pede). Rulings que o humano assina sabendo: R10/R17
(toque depende do estado exibido; texto do design divergente do código), R14 (gatilho pode sobreviver à
tela apagada; `onRestart` relê sem alternar), R24 (D +7,5 contra +6 do design), R25. O eixo Standards é
rodado à parte e inserido pelo controlador.

## Baseline (L0)
<!-- Filled at implementation start (after Gate 1.5 and a green check-tasks, before the first task).
     See task-verify Level 0. -->
Base SHA: e53f3e0
Reused evidence: —

| Subproject | Command | Result (exit) |
|------------|---------|---------------|
| app (ainda inexistente) | `./gradlew ktlintCheck detekt lintDebug` | 127 — `./gradlew` não existe |
| app (ainda inexistente) | `./gradlew testDebugUnitTest` | 127 — `./gradlew` não existe |
| app (ainda inexistente) | `./gradlew assembleRelease` | 127 — `./gradlew` não existe |
| app (ainda inexistente) | `./gradlew test` | 127 — `./gradlew` não existe |

Human decision (if red): todos os 4 comandos aceitos como known-red — repositório greenfield, sem projeto Gradle até a Task 1, que cria o projeto e prova o conjunto verde no seu estado final. Ricardo Nogueira, 2026-10-24.

## Visual checkpoints
<!-- visual-approved: change 2026-10-aod-toggle-complication tasks 4,5,7,11,12,13,15,16 by Ricardo Nogueira on 2026-10-25 -->
<!-- visual-approved: change 2026-10-aod-toggle-complication tasks 4,5,7 by Ricardo Nogueira on 2026-10-25 -->
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
Preview: release assinado instalado por `adb install -r app/build/outputs/apk/release/app-release.apk` + `pm grant` (o autor operou o relógio; mesmo app da premissa de Dev-run, variante release)

| Round | Item (human feedback) | Fix (commit) | L1 |
|-------|-----------------------|--------------|----|
| 1 | Disco cinza atrás da complication | Nenhum: é o fundo do slot `SMALL_IMAGE` desenhado pelo mostrador, não do app (bitmap transparente) | — |
| 1 | Aro na complication deixou o "AOD" pequeno | Reabertura do Gate 1: Task 15 (aro) e Task 16 (aro retirado, `fdcc5b6`) | verde |

### Rodada pós-aprovação (2026-10-25, lista manual no pacote `rs.prelude.aodtoggle`)

| Item | Achado | Commit do conserto | L1 | Conferido pelo autor |
|---|---|---|---|---|
| T4 / R8 | "AOD unavailable" quebrava em duas linhas e a segunda era cortada na tela redonda | `9735f06` (14sp, uma linha, padding lateral 32dp) | verde | sim — texto inteiro |
| Arte / ícone | O "D" parecia mais perto do "O" que o "A" | `e35156d` (D +7,5; ruling R24) | verde | sim — "ficou harmônico" |

## Lista manual (R10) — resultados

Executada em 2026-10-25 por Ricardo Nogueira (operação no relógio) e pelo agente (adb), sobre o release
`rs.prelude.aodtoggle` assinado com a keystore da prelude-rs (`O=prelude-rs`), no OnePlus Watch 3
(OPWE242, Android 14, build `OPWE242_11_A.165`). Mostrador 1: Gravity (`com.oplus.wearos.watchface.gravity`).
Mostrador 2: "Chic" no OHealth (`com.oplus.wearos.watchface.zhenmo.style`, slots 1–3 aceitam `SMALL_IMAGE`).
Os itens marcados (pacote antigo) foram feitos antes da Task 17 sobre `cc.floresta.aodtoggle` e
refeitos no pacote novo onde indicado.

| Item | Verifica | Resultado | Observação |
|---|---|---|---|
| 0a | Premissa 1 | OK | `connectedDebugAndroidTest` 1/1 no pacote antigo (manhã) e no novo (14:17, serial mDNS — R23) |
| 0b | R4 | OK | só `package:rs.prelude.aodtoggle`; `cc.floresta.aodtoggle` desinstalado |
| 0c | R4 | OK | Gravity: `ambient_enabled` 0 → 1 após toque; `doze_enabled` acompanhou (pacote antigo 13:16; novo 14:18→14:21) |
| F1 | R1, R12 | OK (Gravity e Chic) | "AOD Toggle" sob o cabeçalho "AOD"; arte N1 sem aro, branca / âmbar / cinza; o mostrador desenha um disco cinza atrás do slot (não é do app) |
| F2 / T8 | N7 | OK | no carregador com `svc power stayon true`: mudança em Configurações às 14:39:15, complication acompanhou às 14:41:40 (2 min 25 s, inclui o tempo de aviso do autor); `stayon` desligado depois |
| F3 | R3 | OK | sem permissão, cinza ao recarregar o mostrador, sem toque |
| F4 | R6 | OK | com a complication cinza, `pm grant` e toque: ficou âmbar; `ambient_enabled` ficou 1 (não alternou) |
| F5 | R4 | OK (Gravity e Chic) | Configurações, pulso abaixado (esmaecida × apagada) e cor acompanham nos dois sentidos |
| F6 | R5 | n/a aqui | coberto pelo teste de unidade (R9) |
| F7 | R7 | OK | ao sair do gatilho a complication já mostra o estado final |
| F8 | N1 | OK (Gravity e Chic) | < 1 s do toque até a nova cor (observação do autor) |
| F9 | N1 | OK | < 1 s do botão e do interruptor até o novo estado |
| T1 | N4 | OK | `aapt dump permissions`: só `android.permission.WRITE_SECURE_SETTINGS`; `UPDATE_PERIOD_SECONDS` = 0x12c |
| T2 | N5 | OK | sem permissão: linhas `AodToggle: AOD indisponivel: sem permissao WRITE_SECURE_SETTINGS`; caminho feliz sem linhas; chave ausente e escrita sem efeito cobertas pelos testes de unidade |
| T3 | R7 | OK | botão mapeado alterna e mostra imagem + interruptor; interruptor alterna; botão com a tela aberta alterna; apagar/acender mostra o estado atual |
| T4 | R8 | OK após conserto | imagem cinza, "AOD unavailable" (cortado na 1ª vez → `9735f06`), interruptor desabilitado sem resposta; chave não mudou |
| T6 | N6 | OK | `dumpsys alarm` 0, `dumpsys jobscheduler` 0 linhas do pacote (16:11) |
| T7 fase 1 | N6 | OK | 14:44:45 → 15:45:17 fora do carregador, complication no Gravity, sem toques: `AodComplicationService` launches 8 (≤ ~12), CPU do app 0,66 s, processo em cache 1h00m33s |
| T7 fase 2 | N6 | OK (janela de 25 min — R25) | 16:11:28 → 16:36:39 fora do carregador, sem a complication em mostrador nenhum: o app não aparece no `batterystats` (0 acionamentos do serviço, 0 mAh na estimativa por UID). O relógio gastou 33 mAh no período, com a tela ligada 9 min 36 s (14×), Wi-Fi 11,2 mAh (Play Store 3,9; adb sem fio 3,3) e o sistema/sysui |

## Requirement walk
<!-- Testes de unidade: app/src/test/java/rs/prelude/aodtoggle/core/ (24 casos, rodados no L2 deste gate).
     Teste instrumentado: app/src/androidTest/java/rs/prelude/aodtoggle/system/SystemAodSettingsTest.kt (rodado no relógio, ver Regression standing).
     Itens da lista manual: § "Lista manual (R10) — resultados" acima. -->

| Req ID | Implemented (file/symbol) | Tested (test name) | Verified how | Result |
|--------|---------------------------|--------------------|--------------|--------|
| R1 | `AndroidManifest.xml` (serviço `SUPPORTED_TYPES = SMALL_IMAGE`); `AodComplicationService.onComplicationRequest`/`dataFor` (`SmallImageType.ICON`, só `ComplicationType.SMALL_IMAGE`); `core/Presentation.kt` `presentationOf` (#FFC107 / #FFFFFF / #757575); `system/AodImage.icon` (tint SRC_IN no bitmap); `res/drawable/aod_text.xml` (arte N1, anel r 16,95 traço 3,6 → Ø ext. 37,5 = 1,25 × 30, dois ponteiros, sem aro) | `PresentationTest` (`ligado e ambar`, `desligado e branco`, `indisponivel e cinza para qualquer motivo`) | Unit (L2); lista F1 OK no Gravity e no Chic (branco/âmbar/cinza, sem aro); revisão visual aprovada (tasks 4,5,11,15,16); `aapt dump xmltree`: `SUPPORTED_TYPES="SMALL_IMAGE"` | PASS |
| R2 | `SystemAodSettings.read()` (`Settings.Global` `AOD_KEY = "ambient_enabled"`, `null` em `SettingNotFoundException`/`SecurityException`); `AodToggle.readState()` (null → `KEY_MISSING`, 1 → On, outro → Off) | `AodToggleTest` (`chave ausente e indisponivel`, `valor 1 e ligado`, `valor 0 e desligado`, `outro valor e desligado`); `SystemAodSettingsTest.withGrantTheAppCanReadAndWriteTheKey` | Unit (L2); instrumentado no OPWE242 (2×, pacotes antigo e novo); lista F2/T8 OK (mudança em Configurações refletida) | PASS |
| R3 | `AodToggle.readState()` checa `hasWritePermission()` **antes** de `read()`; `SystemAodSettings.hasWritePermission()` (`checkSelfPermission`) | `AodToggleTest.sem permissao e indisponivel e nao le a chave` (assere `readCount == 0`) | Unit (L2); lista F3 OK (cinza sem toque) | PASS |
| R4 | `ToggleReceiver.onReceive` (ação TOGGLE → `aodToggle(context).toggle()` → `requestComplicationRefresh`); `AodComplicationService.tapIntentFor` (`PendingIntent.getBroadcast` explícito, `FLAG_IMMUTABLE`); `complication/ComplicationRefresh.kt` | `AodToggleTest` (`toggle de ligado escreve 0 e devolve desligado`, `toggle de desligado escreve 1 e devolve ligado`); `TapActionTest` (`ligado alterna`, `desligado alterna`); `SystemAodSettingsTest` | Unit (L2); instrumentado; lista 0b, 0c, F5 OK nos dois mostradores (Configurações, pulso abaixado e cor acompanham) | PASS |
| R5 | `AodToggle.toggle()`: escreve, relê via `current()` e devolve o relido; log "escrita sem efeito" | `AodToggleTest.escrita sem efeito devolve estado relido e registra log` | Unit (L2); lista F6 n/a no relógio (não reproduzível), remetida ao unit | PASS |
| R6 | `core/TapAction.kt` `tapActionFor` (Unavailable → REFRESH); `ToggleReceiver` (REFRESH/ação desconhecida → só `requestComplicationRefresh`); `AodToggle.toggle()` não escreve quando indisponível (defesa em profundidade) | `TapActionTest` (`indisponivel por permissao so redesenha`, `indisponivel por chave ausente so redesenha`); `AodToggleTest` (`toggle sem permissao nao escreve`, `toggle com chave ausente nao escreve`) | Unit (L2); lista F4 OK (`pm grant` + toque → âmbar, `ambient_enabled` não mudou). Implementação diverge do texto do design — ruling R10/R17, aceito abaixo | PASS |
| R7 | `trigger/TriggerActivity` (`onCreate` sem estado salvo e `onNewIntent` → `toggleAndRender`; `setOnClickListener` no `Switch`; `render` via `presentationOf`/`triggerViewOf`/`AodImage`; `requestComplicationRefresh` a cada alternância; sem `finish()`); manifesto `MAIN/LAUNCHER`, `singleTop`, `noHistory`, `excludeFromRecents`; `layout/activity_trigger.xml` (imagem + `Switch` rótulo `@string/trigger_switch_label` = "AOD"); `core/TriggerView.kt` | `TriggerViewTest` (`ligado e marcado habilitado e sem texto`, `desligado e desmarcado habilitado e sem texto`) | Unit (L2); lista T3 OK (botão mapeado, interruptor, botão com a tela aberta, apagar/acender), F7 OK, F9 OK; revisão visual (tasks 7, 13) | PASS |
| R8 | `triggerViewOf(Unavailable)` = desmarcado, desabilitado, texto visível; `TriggerActivity.render` (`isEnabled`, `label` "AOD unavailable" `VISIBLE`); `toggle()` não escreve quando indisponível; layout 14sp, `maxLines=1`, padding 32dp (`9735f06`) | `TriggerViewTest.indisponivel e desmarcado desabilitado e com texto para qualquer motivo`; `AodToggleTest.toggle sem permissao nao escreve` | Unit (L2); lista T4 OK após `9735f06` (texto cortado na 1ª execução; conserto conferido pelo autor) | PASS |
| R9 | `app/src/test/java/rs/prelude/aodtoggle/core/` — `AodToggleTest` (14), `PresentationTest` (3), `TapActionTest` (4), `TriggerViewTest` (3); `FakeAodSettings` | Um caso por estado (ligado/desligado/indisponível) e por causa de indisponível (permissão, chave ausente) + escrita sem efeito, mapeados para cor/texto (`presentationOf`) e tela (`triggerViewOf`) | `./gradlew testDebugUnitTest` neste gate: 24 testes, 0 falhas, 0 erros (`app/build/test-results/testDebugUnitTest/*.xml`) | PASS |
| R10 | `docs/manual-checklist.md` (itens 0a–0c, F1–F9, T1–T4, T6–T8; tabela de cobertura R1–R8, R12, N1, N4–N7) | — (lista manual) | Resultados no § "Lista manual (R10) — resultados": data 2026-10-25, relógio OPWE242 build `OPWE242_11_A.165`, mostradores Gravity e Chic, cada item OK / n/a / OK após conserto. Observação: F1, F5 e F8 registram os dois mostradores; F3, F4 e F7 não dizem em qual mostrador rodaram (a lista pede a tabela por mostrador). A spec pede a lista rodada em ≥ 2 mostradores cobrindo os requisitos, o que os itens dependentes de mostrador (arte, toque, latência) cumprem | PASS |
| R11 | `README.md` (Prerequisites, release keystore, Build, Connect adb over Wi-Fi, Install and grant, Use it, Troubleshooting, Development) | — (documento) | Conferido neste gate que comandos, pacote `rs.prelude.aodtoggle`, tarefas Gradle (`assembleRelease`, `installDebug`, `connectedDebugAndroidTest`, `ktlintCheck`, `detekt`, `lintDebug`, `testDebugUnitTest` — todas em `./gradlew tasks --all`) e o caminho `app/build/outputs/apk/release/app-release.apk` existem; o README foi o roteiro da lista (cabeçalho da lista remete às seções do README) | PASS |
| R12 | `res/values/strings.xml` `complication_name` = "AOD Toggle", `app_name` = "AOD"; debug "AOD Toggle (debug)"/"AOD (debug)"; manifesto: serviço `android:label="@string/complication_name"`, activity/receiver sem label (ruling R5) | — (recurso) | Lista F1 OK nos dois mostradores ("AOD Toggle" sob o cabeçalho "AOD"); `aapt dump xmltree` mostra label próprio no serviço | PASS |

## NFR verification

| NFR ID | Target | Measured value | Method / command | Result |
|--------|--------|----------------|------------------|--------|
| N1 | ≤ 1 s do toque/botão/interruptor ao novo estado visível | "< 1 s" nos dois mostradores (F8) e no botão e interruptor (F9) | Observação do autor no relógio, registrada na lista. Os campos de tempo da lista (3 medidas por item, cronômetro ou gravação) **não foram preenchidos** — o método é percepção, não cronometragem. Ver "Deferred / waived items" | PASS (método a confirmar no sign-off) |
| N2 | No target | — | — | n.a. |
| N3 | n.a. (sem tenant, sem rede) | Sem permissão de rede no APK | Coberto por N4 | PASS |
| N4 | Só `WRITE_SECURE_SETTINGS` | `uses-permission: name='android.permission.WRITE_SECURE_SETTINGS'` (única linha); nenhum `<permission>` | Rodado neste gate sobre o APK que este gate construiu: `/opt/android-sdk/build-tools/36.0.0/aapt dump permissions app/build/outputs/apk/release/app-release.apk`; idem lista T1. Manifesto remove `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (`tools:node="remove"`) | PASS |
| N5 | Toda falha → linha no logcat sob tag única; caminho feliz sem linhas | Sem permissão: `AodToggle: AOD indisponivel: sem permissao WRITE_SECURE_SETTINGS`; caminho feliz sem linhas | Lista T2 (`adb logcat -s AodToggle`); chave ausente e escrita sem efeito por `AodToggleTest` (`caminho feliz nao registra log`, `escrita sem efeito ... registra log`, `indisponivel por ... registra um log por chamada de toggle`, `current indisponivel registra log`). Tag única `LOG_TAG = "AodToggle"` em `SystemAodSettings.kt`. Observação: na chave ausente o adaptador e o núcleo registram uma linha cada (2 linhas, mesma tag) — compatível com "gera uma linha" lido como ≥ 1, e a lista T2 já diz isso | PASS |
| N6 | Só a atualização periódica de 5 min; sem serviço/alarme/job próprio; ≤ ~12 acionamentos/h com a complication, 0 sem ela | `UPDATE_PERIOD_SECONDS` = 0x12c (300); alarm 0, jobscheduler 0; fase 1 (1h00m, com complication): 8 launches, CPU 0,66 s; fase 2 (**25 min**, sem complication): 0 launches, 0 mAh | `aapt dump xmltree` (neste gate); lista T6, T7 fase 1 e fase 2. A fase 2 usou 25 min em vez de ~1 h (ruling R25, decisão do autor, bateria a 19%). Código: nenhum `Service` próprio além do provider, nenhum `AlarmManager`/`JobScheduler`/observer no diff | PASS (janela de R25 a confirmar no sign-off) |
| N7 | Mudança feita em Configurações aparece em ≤ ~5 min com a tela ligada | 2 min 25 s (inclui o tempo de aviso do autor) | Lista F2/T8, no carregador com `svc power stayon true` (ruling R13) | PASS |
| N8 | Retirado na reabertura de 2026-10-25 | — | — | retirado |

## Scope audit — unspecified additions
<!-- From the inverse walk over the diff. Each item: revert, or human-approved spec amendment. -->

Walk inverso sobre `git diff e53f3e0 HEAD` (48 arquivos). Motivação de cada grupo:

| Arquivo / símbolo / dependência | Motivado por |
|---|---|
| `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/libs.versions.toml`, `gradle/wrapper/*`, `gradlew(.bat)`, `.editorconfig`, `config/detekt/detekt.yml` (`maxIssues: 0`), `.gitignore` (`*.jks`, `*.keystore`, `local.properties`) | Task 1 (N4, comandos do `task-verify`); Global Constraint "nada de keystore no repositório" |
| Dependências: `watchface-complications-data-source-ktx` 1.3.0, `core-ktx` 1.18.0 (runtime); JUnit 4, `androidx.test:runner`, `androidx.test.ext:junit` (teste); plugins AGP, Kotlin, ktlint, detekt | Design § Stack (só duas de runtime — conferido) |
| `app/build.gradle.kts` (assinatura `aodtoggle.keystore.*`, `applicationIdSuffix ".debug"`, R8 desligado, SDKs 34/34/36) | Design § Stack / Release (pedido do autor, aceito na Gate 1.5) |
| `AndroidManifest.xml` | R1, R4, R6, R7, R12, N4, N6 |
| `core/AodSettings`, `AodState`, `AodToggle`, `Presentation`, `TriggerView` | R1–R3, R5–R9, N5 |
| `core/TapAction.kt` (`TapAction`, `tapActionFor`), `ToggleReceiver.actionName`, as duas ações de broadcast | R6 (ruling R10) — não é comportamento além da spec: é o que faz R6 valer; diverge só do texto do design (R17) |
| `system/SystemAodSettings` (+ `aodToggle` fábrica), `system/AodImage` (`AOD_IMAGE_SIZE_PX`) | R1–R5, N5 |
| `complication/AodComplicationService`, `ToggleReceiver`, `ComplicationRefresh.requestComplicationRefresh` | R1–R7 |
| `trigger/TriggerActivity`, `layout/activity_trigger.xml`, `values/themes.xml` | R7, R8 |
| `drawable/aod_text.xml`, `drawable/ic_launcher_foreground.xml`, `mipmap-anydpi/ic_launcher*.xml` | R1; ícone do app pela 1ª reabertura da spec ("o mesmo desenho, em âmbar, é o ícone do app") e design (prévia nº 3) |
| `values/strings.xml`, `debug/res/values/strings.xml` | R7, R12; design (rótulo do debug) |
| Testes `app/src/test/...`, `app/src/androidTest/...` | R9; premissa 1 do design |
| `README.md`, `docs/manual-checklist.md` | R11, R10 |
| `CLAUDE.md` (título `wearos-aod-toggle`) | Task 17 (design reaprovado) |
| `CONTEXT.md` (glossário) | Artefato de domínio do `spec-brainstorming`; só documentação, sem comportamento |
| `specs/active/2026-10-aod-toggle-complication/*` | Artefatos da própria change |

**Adições não especificadas** (cada uma com recomendação; nenhuma bloqueia, todas pedem ciência no sign-off):

1. **`TriggerActivity.onRestart` relê e renderiza o estado sem alternar** (ruling R14, commit `8093db8`). Comportamento que nem a spec nem o design descrevem (o design dizia que `noHistory` finalizaria a tela ao apagar). Mantém a tela coerente com R7 ("imagem e interruptor no estado relido") quando ela sobrevive à tela apagada; conferido na lista T3. **Recomendação:** manter; registrar na reescrita do SoT.
2. **Comportamento não determinístico da tela do gatilho ao apagar a tela** (pode fechar ou continuar aberta — R14; README e T3(c) documentam as duas). A spec (R7) só promete "fica aberta até o usuário sair"; continuar aberta cumpre R7 ao pé da letra, fechar ao apagar foi a decisão do autor no design (R12 dos rulings, substituído). **Recomendação:** aceitar; o SoT descreve as duas possibilidades.
3. **`android:allowBackup="false"`** no `<application>` — não pedido pela spec nem pelo design; inofensivo (o app não tem dados). **Recomendação:** manter.
4. **Componentes de dependência no manifesto mesclado** (`androidx.startup.InitializationProvider`, `ProfileInstallReceiver`, `uses-library` `com.google.android.wearable` e `wear-sdk` com `required=false`) — trazidos por `core-ktx`/complications; não pedem permissão (N4 conferido). **Recomendação:** aceitar como efeito das dependências aprovadas.

**Julgamento dos rulings R1–R25** (§ Rulings, abaixo):

| Ruling | Julgamento |
|---|---|
| R1–R6, R8, R9, R11, R13, R15, R16, R18–R23 | Decisões de processo, ferramenta, layout ou documentação dentro do que a spec e o design pedem; nenhum acrescenta comportamento. Aceitáveis. R13 (N7 no carregador com `stayon`) cumpre "com a tela ligada" de N7. R21: o título do `SOURCE-OF-TRUTH.md` fica antigo até uma change futura — anotar no arquivamento |
| R7 | Trailers `Co-Authored-By` de 5 commits nomeiam Opus quando foram Sonnet. Não é escopo; é registro de histórico — o humano decide se reescreve (recomendação: não, o ruling basta) |
| R10 | **Aceitável.** O toque depender do estado exibido é o único jeito de cumprir R6 ("sem mudar o AOD"); `toggle()` ainda recusa escrever se o estado ficou indisponível entre o desenho e o toque. Diverge do texto do design, não da spec |
| R12 | Substituído por R14 |
| R14 | **Aceitável, com ciência no sign-off** (adições 1 e 2 acima) |
| R17 | **Aceito por este gate:** o código cumpre a spec (R6) e o design está desatualizado em `ToggleReceiver`/mapa de R6; a reescrita do SoT segue o código |
| R24 | **Aceitável.** A spec não fixa o deslocamento do D; o ajuste foi pedido e conferido pelo autor no relógio. O design fica com +6; o SoT segue o código (+7,5) |
| R25 | **Precisa de confirmação explícita no sign-off.** Muda o critério de medida que a própria spec fixa para N6 ("~1 h sem ela") para 25 min. O resultado (0 acionamentos, 0 mAh, contra ~3–4 esperados no ritmo da fase 1) separa os casos, e a decisão é do autor; registrado em "Deferred / waived items" |

## Rulings
<!-- Cada decisão tomada na execução sem o humano (o ledger do SP é apagado no fim; o registro mora aqui).
     Um ruling que acrescenta comportamento fora da spec também é listado no audit de escopo acima.
     Sem rulings, `nenhum`. Ao reescrever este arquivo, carregue adiante os rulings já gravados. -->

| # | Task | Ruling (o quê) | Por quê | Custo se errado |
|---|------|----------------|---------|-----------------|
| R1 | 1, 7 | A Task 1 cria `strings.xml` de main ("AOD") e de debug ("AOD (debug)"); a Task 7 só modificaria | O rótulo precisa existir desde a Task 1 | Mover um arquivo |
| R2 | 1 | A Task 1 cria o `gradle.properties` do projeto com `android.injected.androidTest.leaveApksInstalledAfterRun=true` | Achado W2 da rodada 4 do gate | Nenhum |
| R3 | 3 | Sem o relógio acessível, a Task 3 fica BLOCKED em vez de DONE | A premissa 1 só se prova no aparelho | Uma pausa |
| R4 | 3 | O teste instrumentado lê a saída de `pm grant` até EOF antes de asserir; erro do `pm grant` = arnês, permissão falsa após concessão = premissa 1 | Achado W4 da rodada 4 do gate | Reabertura falsa da spec |
| R5 | 5–7 | Serviço, receiver e activity sem `android:label` (herdam o da aplicação) | "AOD (debug)" chega ao editor do mostrador e ao seletor de botão | Achado na revisão visual |
| R6 | 3–9 | Relógio inacessível à noite: a Task 3 implementa e compila o teste instrumentado, a execução no aparelho fica pendente (BLOCKED), e as Tasks 4–9 seguem | O autor estava dormindo; a falha da premissa 1 reabre a spec | Trabalho das Tasks 4–9 perdido se o app não puder escrever a chave |
| R7 | — | Os trailers dos commits 36b5ce0, 8908449, 71e92bd, d24848c e 93bef73 dizem Opus, mas foram escritos por subagentes Sonnet (instrução errada no `constraints.md`, corrigida); histórico não reescrito | Reescrever histórico é decisão do autor | Atribuição errada em 5 trailers |
| R8 | 8 | README em inglês | O autor trabalha em inglês; a regra pt-BR do kit cobre os artefatos SDD | Tradução |
| R9 | 9 | `docs/manual-checklist.md` em pt-BR | Os resultados vão para este `evidence.md` | Tradução |
| R10 | 5, 6 | O toque na complication depende do estado **exibido**: indisponível → REFRESH (só redesenha), ligado/desligado → TOGGLE; decisão em `tapActionFor` (núcleo, testada). Diverge do texto do design (receiver sempre chamava `toggle()`), que não satisfazia o aceite de R6 ("sem mudar o AOD") | A spec é a autoridade; a revisão final achou R6 quebrado de ponta a ponta | Uma string de ação a mais; divergência design/implementação que o validation-gate precisa aceitar |
| R11 | 11 | Raio do anel 16,95 (1,25× de R1), não o 17,2 da prévia; o texto "valores medidos na prévia" do design não vale para o raio | Aviso W3 da rodada 6, aceito na Gate 1.5 de 2026-10-25; editar o design custaria uma rodada além do teto | A revisão visual da Task 11 decide |
| R12 | 13 | (Substituído por R14.) A tela do gatilho não se fecha por tempo; `noHistory` a finaliza quando a tela apaga ou volta ao mostrador (decisão do autor), apesar da restrição global "não se fecha sozinha" | Aviso W4 da rodada 6; a linha da `TriggerActivity` no design carrega a decisão | Comportamento a confirmar na revisão visual |
| R13 | 14 | Medida de N7 com o relógio no carregador e `svc power stayon true` (só vale na energia) | Aviso W5 da rodada 6 | Se o mostrador não ficar visível carregando, a medida de N7 muda de meio |
| R14 | 13, 14 | `onRestart` re-renderiza o estado atual sem alternar; README e T3(c) dizem que apagar a tela pode fechar ou manter a tela do gatilho | Revisão final: a plataforma não finaliza `noHistory` ao dormir; manter a tela cumpre R7 ao pé da letra; R12 (fechamento ao apagar) fica como possibilidade, não promessa | Uma frase de documentação |
| R15 | 13 | Layout do gatilho apertado de antemão (padding vertical 24dp, imagem 80dp) | Revisão final: o texto de R8 podia ser cortado na tela redonda | Ajuste de layout na revisão visual |
| R16 | 11 | Escala do aro do ícone mantida em 72/108 (valor do design), conferida na revisão visual | Revisão final: o aro encosta na máscara | Um ajuste de escala |
| R17 | 5, 6 | O texto do design para `ToggleReceiver` e o mapa de R6 continua divergindo do código (R10); o validation-gate aceita a divergência e a reescrita do SoT segue o código | Revisão final, Minor 6; editar o design exigiria nova rodada do consistency-gate | Texto do SoT |
| R18 | 15 | A Task 15 também ajusta o item F1 da lista manual: "arte N1 dentro do aro, em branco, âmbar e cinza (R1)" | Aviso W6 da rodada 7, aceito na Gate 1.5 | Uma linha da lista |
| R19 | 15, 16 | A Task 15 (aro na complication) foi substituída pela Task 16 (aro retirado); o conteúdo de antes da Task 15 é o de `f68fa1b` | Aviso W6 da rodada 8, aceito na Gate 1.5; editar o design custaria a rodada 9 | Nenhum: o bloco da Task 15 fica só como histórico |
| R20 | 17 | `rootProject.name` passa de `aod-toggle` (não `wearos-complication-aod-toggle`, como diz o design) para `wearos-aod-toggle`; o repositório e a pasta é que se chamavam `wearos-complication-aod-toggle` | Aviso W7 da rodada 9 | Nenhum |
| R21 | 17 | O título de `specs/SOURCE-OF-TRUTH.md` não é renomeado nesta change | A reescrita do SoT no arquivamento só toca as seções declaradas na spec (regra 5(b)), e o título não está entre elas; aviso W8 da rodada 9 | Título antigo no SoT até uma change futura |
| R22 | 17 | O prefixo das propriedades de assinatura continua `aodtoggle.keystore.*` (o autor já atualizou o `~/.gradle/gradle.properties` para `~/IAM/prelude-rs-release.jks`, alias `prelude`); o exemplo de `keytool` do README passa a `~/prelude-rs-release.jks`, alias `prelude`, com `-dname "CN=prelude-rs, O=prelude-rs, C=BR"` | Aviso W9 da rodada 9 | Ajuste de documentação |
| R23 | 17 | `connectedDebugAndroidTest` roda com o relógio conectado pelo nome mDNS, não por `IP:porta` | Com `IP:porta` o AGP falha a tarefa com o teste verde (erro de arnês, não da premissa — regra da lista, item 0a) | Uma linha de README se outro executor tropeçar |
| R24 | 11, 16 | "D" deslocado +7,5 (não +6, como diz o design) em `aod_text.xml` e `ic_launcher_foreground.xml` | Ajuste óptico pedido pelo autor no relógio: a haste reta do D parecia mais perto do anel que a diagonal do A; conferido "harmônico" pelo autor em 2026-10-25 | O design fica com o valor antigo (+6) |
| R25 | — | A fase 2 da medida de N6 (sem a complication) fecha com 25 min, não 1 h | Bateria do relógio em 19%; decisão do autor; 0 acionamentos em 25 min contra ~3 esperados no ritmo da fase 1 (8/h) já separa os casos | Janela menor que a pedida pela lista |

## Out-of-scope respected
<!-- Confirm each out-of-scope item was not implemented. -->

| Item fora de escopo | Conferido |
|---|---|
| Publicação na Play Store | Nenhuma configuração de publicação; README: sideload por adb. OK |
| Tiles, mostradores, app no telefone | Nenhum `TileService`, `WatchFaceService` nem módulo de telefone (único módulo `:app`). OK |
| Agenda do AOD (`start_time_aod` / `over_time_aod`) | Nenhuma referência no código; única chave é `AOD_KEY = "ambient_enabled"`. OK |
| `SHORT_TEXT` / `MONOCHROMATIC_IMAGE` | `SUPPORTED_TYPES = SMALL_IMAGE`; serviço devolve `null` para outro tipo. OK |
| Tela de configuração | Única activity é `TriggerActivity`. OK |
| Outros relógios / Wear OS 6 | Nada específico; verificado só no OPWE242. OK |
| Escuta em tempo real (observer, serviço permanente) | Nenhum `ContentObserver`, serviço em primeiro plano, alarme ou job no diff; lista T6. OK |
| Alternativa quando a chave não pode ser escrita (abrir Configurações) | Nenhuma; indisponível só mostra cinza. OK |

## Regression standing
<!-- Commands run (test suite, lints, build) and exit status. -->

- 2026-10-25 — **`task-verify` Level 2 rodado por este gate** no HEAD `0e41891`, árvore limpa, JDK 17 (`JAVA_HOME=/home/ricardo/.sdkman/candidates/java/17.0.18-tem`):
  `./gradlew clean ktlintCheck detekt lintDebug testDebugUnitTest test assembleRelease` → **exit 0, BUILD SUCCESSFUL**
  (88 tarefas). `ktlintCheck`: Main/Test/AndroidTest/KotlinScript verdes (os demais source sets estão vazios, SKIPPED).
  `detekt` verde (`maxIssues: 0`). `lintDebug`: 0 erros, 4 avisos (`ContentDescription` no `ImageView` do layout —
  definido em runtime por `render`; `DataExtractionRules`; 2× `GradleDependency`), com `warningsAsErrors = false` do design.
  Testes: 24, 0 falhas, 0 erros (`AodToggleTest` 14, `PresentationTest` 3, `TapActionTest` 4, `TriggerViewTest` 3);
  `test` no AGP 9 roda só a variante debug (não há `testReleaseUnitTest`).
- **Equivalência com CI (regra 7):** não há `.env` no repositório; as variáveis do ambiente são só `ANDROID_HOME`/`JAVA_HOME`.
  A única entrada local é a assinatura do release, lida das propriedades `aodtoggle.keystore.*` do
  `~/.gradle/gradle.properties` do autor — sem elas o mesmo conjunto roda verde e só o APK sai `-unsigned`. O CI do
  repositório (`.github/workflows/ci.yml`, `build-check`) é o do kit e **não roda Gradle** (decisão do design:
  "CI do repositório não ganha build Gradle nesta change"); portanto **nenhum CI verde substitui este L2**, que é a
  evidência de L2 desta change. O L3 (`connectedDebugAndroidTest`) não se aplica: a change vai para `dev`.
- **Artefato construído (regra 8):** o APK que este gate construiu, `app/build/outputs/apk/release/app-release.apk`,
  verifica com `/opt/android-sdk/build-tools/36.0.0/apksigner verify --print-certs`: `Verifies`, esquema v2,
  `Signer #1 certificate DN: CN=Ricardo Nogueira, OU=prelude-rs, O=prelude-rs, L=Florianópolis, ST=SC, C=BR`
  (SHA-256 `48435238…5a9e2f`). `aapt dump permissions` → só `WRITE_SECURE_SETTINGS`; `aapt dump xmltree` →
  `package="rs.prelude.aodtoggle"`, `UPDATE_PERIOD_SECONDS=0x12c`, receiver `exported=false`. A instalação e o
  smoke no relógio do release assinado estão nas linhas de dispositivo abaixo e na lista manual (0b, F1–F9, T1–T8) — este
  gate não tem o relógio e não reinstalou.
- **Comandos operacionais (passo 6):** os comandos do `README.md` e de `docs/manual-checklist.md` resolvem contra o
  projeto real — pacote `rs.prelude.aodtoggle` / `rs.prelude.aodtoggle.debug`, componente
  `rs.prelude.aodtoggle.trigger.TriggerActivity`, tarefas `assembleRelease`, `installDebug`, `connectedDebugAndroidTest`,
  `ktlintCheck`, `detekt`, `lintDebug`, `testDebugUnitTest` (todas listadas por `./gradlew tasks --all`), caminho do APK
  e tag `AodToggle` (= `LOG_TAG`). Nenhuma referência a `cc.floresta` fora de `specs/`, salvo os `adb uninstall` do
  pacote antigo no README e na lista (pedido pela Task 17). Os comandos `adb` em si dependem do relógio e foram
  exercidos na lista manual.
- **Revisão visual (passo 7):** tasks VISUAL nos blocos do `design.md`: 4, 5, 7, 11, 12, 13, 15, 16. A primeira linha de aprovação
  de "Visual checkpoints" (tasks 4,5,7,11,12,13,15,16, Ricardo Nogueira, 2026-10-25), na forma exata do lançador
  e com o id desta change, cobre todas. A segunda linha (tasks 4,5,7) é a aprovação anterior às reaberturas, mantida.
  Os dois consertos depois da aprovação (`9735f06`, `e35156d`) estão na "Rodada pós-aprovação", conferidos pelo autor. OK.

- 2026-10-25 — `./gradlew connectedDebugAndroidTest` no OnePlus Watch 3 (OPWE242, Android 14 / API 34): exit 0, `SystemAodSettingsTest` 1 teste, 0 falhas. Premissa 1 provada (o app concedido lê e escreve `ambient_enabled`); valor do AOD restaurado ao anterior (`0`). Fecha o BLOCKED de R3/R6.
- 2026-10-25 14:17 — Task 17 (pacote `rs.prelude.aodtoggle.debug`): `./gradlew connectedDebugAndroidTest` no OPWE242: exit 0, `SystemAodSettingsTest` 1 teste, 0 falhas — premissa 1 refeita no pacote novo. Observação de arnês: com o relógio conectado por `IP:porta` (`adb connect 192.168.1.122:33233`) o AGP marca a tarefa como falha mesmo com o teste passando (a instrumentação crua dá `INSTRUMENTATION_CODE: -1`, o XML 1/1 verde); com o nome mDNS (`adb connect "adb-…(2)._adb-tls-connect._tcp"`) a tarefa fica verde. Release `rs.prelude.aodtoggle` instalado (14:18:05), assinado `O=prelude-rs`, permissão concedida; `cc.floresta.aodtoggle` desinstalado.

## Standards (eixo separado — validation-gate passo 8)
<!-- Sem código no diff → `n.a. — <motivo>`. Escopo é o diff da change, não o repo.
     Declare a isolação: subagente separado do eixo Spec, ou a ausência dele.
     Todo achado sai daqui como `fixed` (com ref) ou `accepted by <nome> on <data>` — nunca por omissão.
     Os 12 smells vivem no `validation-gate`; esta seção reporta, não os lista. -->

Isolação: subagente separado do eixo Spec. Padrão documentado: não há `CODING_STANDARDS.md` nem `CONTRIBUTING.md`; valem os 12 smells, como julgamento. Escopo: `git diff e53f3e0 HEAD -- app/`.

| Achado | Smell | Onde (file:line do diff) | Por que morde aqui | Desfecho |
|---|---|---|---|---|
| S1 — `Log.w(LOG_TAG, it)` escrito duas vezes (default de `SystemAodSettings.log` e lambda de `aodToggle()`) | Duplicated Code | `system/SystemAodSettings.kt:17` e `:46` | Mudar tag ou nível exige editar os dois pontos, que podem divergir sem aviso | pendente — decisão do autor |
| S2 — `ToggleReceiver` também só redesenha (`REFRESH`, estado indisponível) | Mysterious Name | `complication/ToggleReceiver.kt:13`; `complication/AodComplicationService.kt:41` | Quem lê "toggle receiver" no estado indisponível espera uma alternância que não acontece (R6) | pendente — decisão do autor |
| S3 — `render(aodToggle(this).current())` em `onCreate` (else) e em `onRestart` | Duplicated Code | `trigger/TriggerActivity.kt:38` e `:51` | A política "reler sem alternar" fica espalhada em dois ciclos de vida | pendente — decisão do autor |

## Deferred / waived items
<!-- DEFERRED NFRs with their homolog/prod runbook; waivers need the human's name and date. -->

Nenhum item DEFERRED. Itens que o sign-off precisa **confirmar explicitamente** (nome e data na linha de confirmação):

| Item | O que diverge do critério da spec | Decidido por | Confirmação no sign-off |
|---|---|---|---|
| N6 — ruling R25 | Fase 2 (sem a complication) medida em 25 min, não "~1 h": 0 acionamentos, 0 mAh | Ricardo Nogueira (autor), 2026-10-25, ruling R25 (bateria a 19%) | aceito por Ricardo Nogueira em 2026-10-25 |
| N1 — método | Latência registrada como "< 1 s" por observação do autor; os três tempos por item que a lista pede (cronômetro ou gravação) não foram anotados | Execução da lista pelo autor, 2026-10-25 | aceito por Ricardo Nogueira em 2026-10-25 |
| Adições não especificadas 1–4 e rulings R10, R14, R17, R24 | Ver "Scope audit" — aceitáveis na opinião deste gate | — | aceito por Ricardo Nogueira em 2026-10-25 |

Se o sign-off recusar algum item: N6 → refazer a fase 2 de T7 com ~1 h (`adb shell dumpsys batterystats --reset`, ~1 h sem
a complication em mostrador nenhum, `adb shell dumpsys batterystats | grep -A30 rs.prelude.aodtoggle`); N1 → refazer F8/F9
com `adb shell screenrecord /sdcard/n1.mp4` e contagem de quadros, anotando os tempos; adições → reverter o commit
indicado ou emendar a spec com aprovação humana.
