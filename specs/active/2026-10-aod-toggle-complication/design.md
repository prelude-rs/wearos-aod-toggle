# Design: Complication e gatilho para alternar o AOD no OnePlus Watch 3

Change-ID: 2026-10-aod-toggle-complication
Status: Approved
<!-- approved-by: Ricardo Nogueira on 2026-10-25 -->
<!-- approved-content: sha256:f9a6d9712146 -->
Spec: ./spec.md

## Approach summary

Um único módulo Android (`app`), Kotlin, cuja única tela é a do gatilho (imagem + interruptor). O núcleo é Kotlin
puro: um **porto** `AodSettings` (ler o valor, escrever o valor, saber se há permissão) e, sobre ele, a
lógica de estado (ligado / desligado / indisponível), a alternância com releitura e os mapeamentos estado →
apresentação (cor + texto) e estado → tela do gatilho (interruptor marcado/habilitado, texto visível). Três bordas Android usam esse núcleo: o serviço da complication
(`SuspendingComplicationDataSourceService`, só `SMALL_IMAGE`), um `BroadcastReceiver` que recebe o toque
na complication e uma `Activity` de lançador (o gatilho). A imagem "AOD" — com o O desenhado como relógio
(variação N1) — é um único vector drawable de uma cor, rasterizado já tingido na cor do estado. A
complication declara atualização periódica de 5 min, feita pelo sistema só enquanto está num mostrador
ativo (N6/N7).

Abordagens consideradas: (a) **trampolim** — toque na complication abre uma activity transparente que
alterna e fecha (a proposta do brief); (b) **receiver** — toque dispara um broadcast que alterna sem
janela; (c) gatilho e complication compartilhando a mesma activity. Escolhida (b) para a complication,
com activity só para o gatilho: sem janela piscando, menos peças, caminho mais curto para N1; a
restrição de trampolim do Android 12 vale para notificações, não para complications.

## Stack & dependencies

Decisões já assentadas no SoT (Stack): Kotlin nativo Wear OS, Gradle com wrapper. Nesta change:

| Item | Escolha | Justificativa |
|---|---|---|
| Build | Gradle wrapper + Kotlin DSL + version catalog `gradle/libs.versions.toml`; AGP, Kotlin e libs na **última versão estável compatível com JDK 17**, resolvidas e fixadas na Task 1 | Pedido do autor; a Task 1 prova a escolha com build verde. |
| JDK | 17 (toolchain Gradle) | Prereq já registrado em `task-verify`. |
| SDKs | `minSdk 34`, `targetSdk 34`, `compileSdk 36` | Só o OW3 (API 34) é verificado; compilar contra 36 expõe depreciações do Wear OS 6 como aviso, sem optar pelo comportamento de 36. |
| `androidx.wear.watchface:watchface-complications-data-source-ktx` | única dependência de runtime além do `androidx.core` | Fornece `SuspendingComplicationDataSourceService`, `SmallImageComplicationData` e `ComplicationDataSourceUpdateRequester`. |
| `androidx.core:core-ktx` | runtime | `ContextCompat`/`toBitmap` para rasterizar o vector tingido. |
| UI do gatilho | Views simples (um layout XML: `ImageView` + `TextView` + `android.widget.Switch` do tema `DeviceDefault`) | Zero dependência de UI; Compose traria uma árvore grande para uma tela com três views. O `Switch` da plataforma já segue o estilo do Wear no `DeviceDefault`. |
| Lint | `org.jlleitschuh.gradle.ktlint` (dá `ktlintCheck`), `io.gitlab.arturbosch.detekt` (regras padrão), Android lint (padrão, `warningsAsErrors` desligado) | Os comandos já registrados em `task-verify`. |
| Testes | JUnit 4 puro na JVM para o núcleo; um teste instrumentado (`androidx.test:runner` + `androidx.test.ext:junit`, só em `androidTest`) para o adaptador do sistema, rodado por `connectedDebugAndroidTest` | O núcleo é Kotlin puro; sem Robolectric. O teste instrumentado é o único jeito de provar cedo que o **app** (não o shell) lê e escreve a chave. |
| Release | assinatura com keystore própria lida de `~/.gradle/gradle.properties` (nunca commitada); sem ela o release sai sem assinatura e o "Artifact smoke" do `task-verify` é registrado `DEFERRED` com o comando exato, nunca verde. Debug com `applicationIdSuffix ".debug"`: debug e release coexistem no relógio, cada um com sua própria concessão `pm grant`, sem conflito de assinatura na instalação; o debug se rotula "AOD (debug)" para não se confundir com o release na lista de apps, no editor do mostrador e no mapeamento de botão. `gradle.properties` fixa `android.injected.androidTest.leaveApksInstalledAfterRun=true`, para que `connectedDebugAndroidTest` não desinstale o debug (e sua concessão) ao terminar. R8 desligado. | Pedido do autor; R8 não compensa num app minúsculo e evita risco de keep-rule no serviço/receiver. |

## Data modeling

Sem persistência, sem tenant (app pessoal). Tipos do núcleo (`cc.floresta.aodtoggle.core`):

```kotlin
enum class UnavailableReason { NO_PERMISSION, KEY_MISSING }

sealed interface AodState {
    data object On : AodState
    data object Off : AodState
    data class Unavailable(val reason: UnavailableReason) : AodState
}

interface AodSettings {               // porto: o único ponto que toca o sistema
    fun hasWritePermission(): Boolean
    fun read(): Int?                  // null = chave ausente ou leitura negada
    fun write(value: Int)
}

data class Presentation(val tintArgb: Int, val label: String)

data class TriggerView(            // o que a tela do gatilho mostra além da imagem
    val switchChecked: Boolean,    // ligado
    val switchEnabled: Boolean,    // falso quando indisponível (R8)
    val showLabel: Boolean,        // texto visível só quando indisponível ("AOD unavailable")
)
```

Regra de estado (`AodToggle.current()`): sem permissão → `Unavailable(NO_PERMISSION)`; senão `read()`
nulo → `Unavailable(KEY_MISSING)`; `1` → `On`; qualquer outro valor → `Off`.

Regra de alternância (`AodToggle.toggle()`): avalia `current()`; se indisponível, devolve esse estado
**sem escrever** (R6, R8); senão escreve o oposto (`On` → 0, `Off` → 1), relê e devolve o estado relido
(R5); se o relido é igual ao anterior, registra "escrita sem efeito" (N5).

Apresentação (`presentationOf(state)`): `On` → âmbar `0xFFFFC107` / "AOD on"; `Off` → branco
`0xFFFFFFFF` / "AOD off"; `Unavailable` → cinza `0xFF757575` / "AOD unavailable". O `label` é o
`contentDescription` da complication e da imagem do gatilho; na tela do gatilho ele só aparece como texto
quando indisponível.

Tela do gatilho (`triggerViewOf(state)`): `On` → marcado, habilitado, sem texto; `Off` → desmarcado,
habilitado, sem texto; `Unavailable` → desmarcado, **desabilitado**, texto "AOD unavailable".

## Interfaces & integration points

| Peça | Pacote | Papel |
|---|---|---|
| `SystemAodSettings` | `cc.floresta.aodtoggle.system` | Implementa o porto: `Settings.Global` `ambient_enabled` (constante `AOD_KEY`, **único ponto** onde a chave aparece — pedido do brief), `checkSelfPermission(WRITE_SECURE_SETTINGS)`. `read()` devolve `null` tanto em `SettingNotFoundException` quanto em `SecurityException` (leitura de chave oculta negada a apps com `targetSdk` ≥ 31), registrando linhas distintas; `write()` captura `SecurityException`. |
| `AodImage` | `cc.floresta.aodtoggle.system` | Rasteriza `R.drawable.aod_text` (arte N1, de uma cor) tingido com `Presentation.tintArgb` num `Bitmap` → `Icon.createWithBitmap`. A cor fica no bitmap, não dependendo de o mostrador respeitar tint de `Icon`. |
| `AodComplicationService` | `cc.floresta.aodtoggle.complication` | `SuspendingComplicationDataSourceService`; tipo suportado só `SMALL_IMAGE` (`SmallImageType.ICON`, que não é recortado como `PHOTO`); `contentDescription` = `Presentation.label`; `tapAction` = `PendingIntent` de broadcast explícito para `ToggleReceiver`; sem imagem ambiente (o mostrador decide); `getPreviewData` devolve o estado `Off`. Rótulo próprio `android:label="@string/complication_name"` ("AOD Toggle"; no debug "AOD Toggle (debug)") — R12; o app continua "AOD". |
| `ToggleReceiver` | `cc.floresta.aodtoggle.complication` | `BroadcastReceiver` não exportado: `AodToggle.toggle()` e `ComplicationDataSourceUpdateRequester.requestUpdateAll()`. |
| `TriggerActivity` | `cc.floresta.aodtoggle.trigger` | Activity de lançador (`MAIN`/`LAUNCHER`, `noHistory`, `excludeFromRecents`, `launchMode="singleTop"`). Ao ser aberta (`onCreate` sem estado salvo) e a cada nova abertura com ela no topo (`onNewIntent`, botão pressionado de novo): `toggle()`, `render(state)`, `requestUpdateAll()`. `render` aplica `AodImage` + `triggerViewOf(state)` (posição e habilitação do interruptor, texto visível só se indisponível). Clique no interruptor (`setOnClickListener`, não `OnCheckedChangeListener`, para que o `render` programático não dispare alternância): `toggle()`, `render` do estado relido, `requestUpdateAll()`. Não se fecha por tempo: sai com o botão ou deslizando (`noHistory` a remove da pilha). Decisão do autor (2026-10-25): quando o relógio apaga a tela ou volta sozinho ao mostrador por inatividade, `noHistory` também a finaliza, e isso conta como "o usuário saiu" (R7); na próxima abertura ela alterna de novo. Em recriação por configuração (`savedInstanceState != null`) só lê e renderiza o estado atual, sem alternar. |

Manifesto: `<uses-permission android:name="android.permission.WRITE_SECURE_SETTINGS"
tools:ignore="ProtectedPermissions"/>` (única permissão; o `tools:ignore` silencia o erro do lint
`ProtectedPermissions`, porque a concessão vem de `pm grant`); os nós
`<permission>` e `<uses-permission>` de `${applicationId}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, que o
`androidx.core` ≥ 1.9 injeta no manifesto mesclado, são removidos com `tools:node="remove"` (o app não
registra receiver dinâmico). `android:exported`: serviço `true` (o sistema faz o bind), activity de
lançador `true`, receiver `false`. Serviço com `android:permission="com.google.android.wearable.permission.BIND_COMPLICATION_PROVIDER"`,
intent-filter `android.support.wearable.complications.ACTION_COMPLICATION_UPDATE_REQUEST`, meta-data
`SUPPORTED_TYPES = SMALL_IMAGE` e `UPDATE_PERIOD_SECONDS = 300` (N6/N7); `uses-feature android.hardware.type.watch`;
`com.google.android.wearable.standalone = true`. Ícone de lançador (prévia de ícone nº 3, escolhida pelo autor):
ícone adaptativo com **fundo transparente** (`@android:color/transparent`) e, no primeiro plano, um aro
circular cinza `#3A3A3A` e a arte N1 em âmbar dentro dele, nas proporções da prévia de ícone nº 3 (aro de espessura
6 e raio 47, arte em escala 0,62, num quadro de 100) reduzidas ao círculo visível do ícone adaptativo
(72 dp de 108 dp); a camada monocromática repete o primeiro plano.

Arte N1 (`aod_text.xml`, viewport 100×100, tudo branco para receber tint): "A" e "D" com os caminhos de
hoje deslocados 6 unidades para fora (A −6, D +6) e centrados na linha (y 35–65); o O é um anel
(`strokeWidth` 3,6, raio do traço 16,95, centro 51,50 — diâmetro externo 37,5 = 1,25× a altura das letras, 30), um
ponteiro de horas (ângulo 35°, comprimento 8,9, espessura 4,05) e um de minutos (270°, comprimento 13,3,
espessura 3,04), pontas arredondadas, e um ponto central de raio 2,15. Valores medidos na prévia escolhida.
A segunda reabertura (2026-10-25) pôs a arte dentro de um aro (Task 15); a terceira, no mesmo dia, o
retirou porque o "AOD" ficava pequeno demais no slot (Task 16): `aod_text.xml` volta a ser só a arte N1
acima, em escala 1.

Logs: tag única `AodToggle`, `Log.w` só nos casos de falha (indisponível por permissão, por chave, escrita
sem efeito). O núcleo recebe um `(String) -> Unit` para registrar, para continuar Kotlin puro.

## Seams sob teste

| Seam (onde) | Existente / novo | O que se observa através dele | Req IDs |
|---|---|---|---|
| API pública do núcleo `cc.floresta.aodtoggle.core` (`AodToggle.current()`, `AodToggle.toggle()`, `presentationOf()`, `triggerViewOf()`), com um `AodSettings` falso | novo | Estado derivado de permissão/valor/chave ausente; escrita feita ou não; estado relido após escrita sem efeito; cor e texto por estado; interruptor marcado/habilitado e texto visível por estado; linha de log por falha | R1, R2, R3, R5, R6, R7, R8, R9, N5 |
| `SystemAodSettings` num teste instrumentado (`connectedDebugAndroidTest`) | novo | O app, com a permissão concedida pelo próprio teste, lê a chave, escreve o oposto, relê o novo valor e restaura o original; `hasWritePermission()` reflete a concessão | R2, R4 |
| O relógio real (lista manual) | existente | Comportamento ponta a ponta: mostrador, Configurações, botão, interruptor, nome no seletor, latência, permissões do APK, logcat, atualizações periódicas (`dumpsys batterystats`) | R1–R8, R10, R12, N1, N4–N7 |

**Justificativa dos seams novos:** o núcleo é o seam mais alto que alcança a lógica de estado sem um
aparelho; as bordas Android são finas e verificadas no relógio (R10). O teste instrumentado do
adaptador é o único ponto em que o app — não o shell — exercita a chave de verdade, e roda na Task 3,
antes das bordas existirem (premissa 1).

## Superfície heurística: código medido

N/A — a spec declara que não há superfície heurística.

## Dev-run premise

- Launch: com o relógio conectado via adb (README), `./gradlew installDebug`, depois
  `adb shell pm grant cc.floresta.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`; abrir o gatilho com
  `adb shell am start -n cc.floresta.aodtoggle.debug/cc.floresta.aodtoggle.trigger.TriggerActivity` e colocar a complication no
  Gravity pelo editor do mostrador.
- Mock/dev-flag strategy: nenhuma — não há backend; a única dependência externa é o próprio sistema do
  relógio, exercido de verdade. O estado indisponível se reproduz com `adb shell pm revoke` da mesma
  permissão.
- Signed exception (Gate 1.5 only): none

## Requirement → design map

| Req ID | Design element that satisfies it |
|--------|----------------------------------|
| R1 | `AodComplicationService` (só `SMALL_IMAGE`) + `AodImage` + `presentationOf` (cores) |
| R2 | `SystemAodSettings.read()` + regra de estado de `AodToggle.current()` |
| R3 | `SystemAodSettings.hasWritePermission()` avaliado antes de ler, em `current()` |
| R4 | `ToggleReceiver` → `AodToggle.toggle()` → `requestUpdateAll()` |
| R5 | Releitura em `AodToggle.toggle()` |
| R6 | `toggle()` não escreve quando indisponível; reavalia e o receiver redesenha |
| R7 | `TriggerActivity` (lançador, `singleTop`) + `AodImage` + `triggerViewOf` + clique no `Switch` → `toggle()` + `requestUpdateAll()` |
| R8 | Mesmo caminho de R7 com `toggle()` devolvendo indisponível sem escrever; `triggerViewOf` desabilita o interruptor e mostra "AOD unavailable" |
| R9 | Testes JUnit 4 do núcleo (`app/src/test`) |
| R10 | `docs/manual-checklist.md`, executada e registrada no `evidence.md` |
| R11 | `README.md` |
| R12 | `android:label="@string/complication_name"` no serviço ("AOD Toggle") |

## NFR mechanisms

| NFR | Por construção | Por teste |
|---|---|---|
| N1 (≤ 1 s) | Toque → broadcast (sem janela) → escrita síncrona de uma chave → `requestUpdateAll()`; gatilho e interruptor mostram o resultado assim que `toggle()` retorna. O tempo entre `requestUpdateAll()` e o redesenho é do sistema e do mostrador, não do app (premissa 2). | Lista manual: gravação/cronômetro nos dois mostradores. |
| N2 | — (sem meta) | — |
| N3 | Sem dados de tenant, sem rede. | Coberto por N4. |
| N4 | Manifesto declara só `WRITE_SECURE_SETTINGS` e remove (`tools:node="remove"`) a `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` injetada pelo `androidx.core`; o manifesto mesclado é conferido na Task 1. | `aapt dump permissions` do APK de release, na lista manual e no fechamento da Task 1. |
| N5 | Falhas passam pelo log do núcleo → `Log.w("AodToggle", …)`; caminho feliz não registra. | Testes do núcleo (log chamado só nas falhas) + `adb logcat -s AodToggle` na lista manual. |
| N6 | `UPDATE_PERIOD_SECONDS = 300`: o sistema chama `onComplicationRequest` (ler + rasterizar) a cada 5 min só enquanto a complication está num mostrador ativo; nenhum serviço em primeiro plano, alarme, job ou observer próprio. Medido antes da reabertura com período 0: 0 acionamentos em 4 min, processo em cache. | Lista manual: `dumpsys alarm` / `dumpsys jobscheduler`; `dumpsys batterystats --reset`, ~1 h com a complication no mostrador (≤ ~12 acionamentos/h, CPU desprezível) e ~1 h sem ela (0). |
| N7 | O mesmo período de N6. | Lista manual: mudar o AOD em Configurações, tela ligada, cronometrar até a complication acompanhar (≤ ~5 min). |
| N8 | Retirado (spec reaberta em 2026-10-25). | — |

## Failure modes & rollout

| Falha | Degradação |
|---|---|
| Sem `pm grant` | Complication cinza; gatilho mostra a imagem cinza, "AOD unavailable" e o interruptor desabilitado; log `NO_PERMISSION`. |
| O sistema espaça a atualização periódica além de 5 min | N7 não se cumpre; risco da spec, medido na lista manual. |
| Chave ausente (sistema mudou) | Idem, log `KEY_MISSING`. |
| Leitura negada ao app (`SecurityException` por chave oculta, `targetSdk` ≥ 31) | Tratada como chave ausente: indisponível, log próprio; nenhum componente quebra. Verificado no relógio na Task 3 — se acontecer, a alternância é inviável e a spec é reaberta (decisão do autor para chave inviável). |
| Escrita aceita mas sem efeito | Mostra o estado relido (o real); log "escrita sem efeito". |
| `SecurityException` na escrita (permissão revogada entre a checagem e a escrita) | Capturada em `SystemAodSettings.write`; a releitura devolve o estado real; log. |
| Mostrador ignora a complication / não aceita `SMALL_IMAGE` | Fora do controle do app; risco da spec (segundo mostrador). |

Rollout: sideload manual (`adb install -r`); rollback = reinstalar o APK anterior ou desinstalar. Sem
migração, sem flag. A reinstalação com a mesma assinatura preserva a permissão concedida; desinstalar
exige novo `pm grant`.

## Decisions log

| Decisão | Opção não tomada | Por quê | ADR? |
|---|---|---|---|
| Toque na complication via `BroadcastReceiver` | Activity trampolim (brief) | Sem janela piscando, menos peças, mais rápido (N1). | Não — fácil de reverter. |
| Tela do gatilho com Views + `android.widget.Switch` | Compose for Wear (`ToggleChip`/`SwitchButton`) | Três views não justificam a árvore de dependências; o `Switch` do `DeviceDefault` já tem o visual do sistema. | Não — fácil de reverter. |
| Clique no interruptor via `setOnClickListener` | `OnCheckedChangeListener` | O `render` programático muda `isChecked`; com o listener de mudança, ele dispararia uma alternância a cada render. | Não. |
| `launchMode="singleTop"` + `onNewIntent` alterna | Instância nova a cada pressão | Pressionar o botão com a tela aberta alterna de novo na mesma tela, sem empilhar instâncias. | Não. |
| Atualização periódica de 300 s | Observer de `Settings`; serviço permanente | O mostrador não pede dados ao acender a tela (medido); observer só vive com o processo, que fica em cache; serviço permanente contraria N6. | Não. |
| Ícone adaptativo com fundo transparente e aro `#3A3A3A` | Fundo `#121212` (antes); ícone legado não adaptativo | Escolha do autor (prévia de ícone nº 3); o adaptativo mantém a máscara redonda do lançador. | Não. |
| Um vector + tint rasterizado em bitmap | Três vectors; bitmap de texto em runtime | Um asset só; a cor vai no bitmap, sem depender do mostrador respeitar tint. | Não — fácil de reverter. |
| Sem imagem ambiente | Contorno cinza / ocultar | O mostrador já tem suas regras de ambiente. | Não. |
| `minSdk 34` / `targetSdk 34` / `compileSdk 36` | min 30; target 36 | Só o OW3 é verificado; 36 compila para expor depreciações. | Não. |
| JUnit 4 puro | JUnit 5; Robolectric | Núcleo Kotlin puro; nada a ganhar com o peso extra. | Não. |
| Keystore própria fora do repo; R8 desligado | Chave de debug; R8 ligado | Pedido do autor (WARNING de escopo a reconhecer no Gate 1.5). O "Artifact smoke" do `task-verify` exige um release **assinado**; a keystore própria é preferência do autor, não exigência. | Não. |
| `applicationIdSuffix ".debug"` no debug | Desinstalar o debug antes do smoke | Sem conflito de assinatura (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) e sem perder a concessão de cada variante. | Não. |
| Teste instrumentado do adaptador na Task 3 | Verificar só pelo gatilho, no fim da Task 7 | Prova a premissa 1 antes de construir o resto; repetível. | Não. |
| CI do repositório não ganha build Gradle nesta change | Adicionar | Fora da spec aprovada; o repositório não tem remoto ainda. | Não. |

## Assumptions

1. O app (não só o shell) consegue ler e escrever `Settings.Global` `ambient_enabled` com `targetSdk 34` e
   `WRITE_SECURE_SETTINGS` concedida por `pm grant`. Contexto da spec: a descoberta provou só o shell, e o
   risco "A concessão `pm grant` … ao app pode se comportar diferente do shell" cobre a escrita; a leitura
   entra no mesmo risco. Verificada no relógio na Task 3 (teste instrumentado), antes do resto. **Se
   falhar** — leitura ou escrita negada ao app —, a alternância é inviável: a execução para e a spec é
   reaberta (decisão do autor no Gate 1.5, a mesma tomada para chave inviável).
2. O redesenho após `requestUpdateAll()` cabe em N1 (≤ 1 s); o atraso é do sistema e do mostrador.
   Verificada pelo item de N1 da lista manual, medido de ponta a ponta (toque → estado visível), sem
   separar tempo do app e do mostrador. **Passar de 1 s num mostrador é falha de N1 nesse mostrador**;
   o autor pode dispensá-la no `validation-gate`, registrada no `evidence.md` com mostrador, tempo
   medido, nome e data (decisão do autor no Gate 1.5).

## Global Constraints

- applicationId e pacote raiz: `cc.floresta.aodtoggle`; debug: `cc.floresta.aodtoggle.debug`.
- `minSdk 34`, `targetSdk 34`, `compileSdk 36`; toolchain JDK 17.
- Chave do AOD: `Settings.Global` `ambient_enabled` (1 = ligado), escrita só em `SystemAodSettings`, constante `AOD_KEY`.
- Cores: ligado `#FFC107`, desligado `#FFFFFF`, indisponível `#757575`.
- Textos: "AOD on", "AOD off", "AOD unavailable" (`contentDescription`; na tela do gatilho só "AOD unavailable" aparece como texto); rótulo do interruptor "AOD".
- Nome da complication no seletor: "AOD Toggle" (debug: "AOD Toggle (debug)"); nome do app: "AOD" (debug: "AOD (debug)").
- Tela do gatilho: não se fecha sozinha.
- Tipo de complication: só `SMALL_IMAGE` (`ICON`); `UPDATE_PERIOD_SECONDS = 300`.
- Arte: variação N1, sem aro (valores em "Interfaces & integration points"); ícone: prévia de ícone nº 3, aro `#3A3A3A`, fundo transparente.
- Única permissão pedida: `android.permission.WRITE_SECURE_SETTINGS`.
- Tag de log: `AodToggle`; log só em falha.
- Dependências de runtime: só `watchface-complications-data-source-ktx` e `core-ktx`.
- Nada de keystore, senha ou `local.properties` no repositório.

## Review Focus

- Janela de corrida entre `hasWritePermission()` e `write()` (permissão revogada no meio) — Task 3.
- O mostrador recebe `Icon` de bitmap e não recorta nem retinge — Task 5 (lista manual da Task 9).
- O `PendingIntent` do toque é explícito, imutável e o receiver não é exportado — Task 6.
- O `render` programático do interruptor não dispara alternância; o clique alterna exatamente uma vez — Task 13.
- `onNewIntent` (botão com a tela aberta) alterna; recriação por configuração não alterna — Task 13.
- Fundo do ícone realmente transparente no lançador da OnePlus (sem disco de fundo imposto pelo sistema) — Task 11 (revisão visual).
- O manifesto mesclado não ganha permissões de dependências — Task 1.
- O redesenho da complication após `requestUpdateAll()` pode passar de 1 s em algum mostrador (premissa 2): medido de ponta a ponta; falha de N1 nesse mostrador, dispensável só no `validation-gate` — Task 9 (item de N1).

## Decomposição

**Justificativa de dimensionamento:** N/A

**Execução:** subagent-driven

### Task 1: Esqueleto Gradle do app com lint, testes e assinatura
**Refs:** N4
**Files:** Create `settings.gradle.kts`, `build.gradle.kts`, `gradle/libs.versions.toml`, `gradle/wrapper/*`, `gradlew`, `app/build.gradle.kts`, `app/src/main/AndroidManifest.xml`, `.editorconfig`, `config/detekt/detekt.yml` (se preciso).
- [ ] Resolver as últimas versões estáveis (AGP, Kotlin, ktlint-gradle, detekt, wear complications, core-ktx, JUnit 4) compatíveis com JDK 17 e fixá-las no catálogo.
- [ ] Manifesto com `WRITE_SECURE_SETTINGS` (`tools:ignore="ProtectedPermissions"`), remoção da `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, `uses-feature watch`, `standalone`.
- [ ] Assinatura de release lida de propriedades Gradle (`aodtoggle.keystore.*`), ausente → sem assinatura; R8 desligado; debug com `applicationIdSuffix ".debug"` e rótulo "AOD (debug)"; `android.injected.androidTest.leaveApksInstalledAfterRun=true` no `gradle.properties` do projeto.
- [ ] Dependências de teste instrumentado (`androidx.test:runner`, `androidx.test.ext:junit`) e `testInstrumentationRunner`.
- [ ] Provar `./gradlew ktlintCheck detekt lintDebug testDebugUnitTest assembleRelease` verde e `aapt dump permissions` listando só `WRITE_SECURE_SETTINGS`.

### Task 2: Núcleo de estado, alternância e apresentação (test-first)
**Refs:** R1, R2, R3, R5, R6, R8, R9
**Files:** Create `app/src/main/java/cc/floresta/aodtoggle/core/*.kt`, `app/src/test/java/cc/floresta/aodtoggle/core/*Test.kt`.
- [ ] Testes primeiro, com `AodSettings` falso: sem permissão → indisponível (sem ler); chave ausente → indisponível; 1 → ligado; 0 → desligado; toggle ligado→desligado e vice-versa; toggle indisponível não escreve; escrita sem efeito → estado relido + log; log só nas falhas; `presentationOf` dá cor e texto de cada estado.
- [ ] Implementar `AodState`, `AodSettings`, `AodToggle`, `Presentation`/`presentationOf` até verde.

### Task 3: Adaptador do sistema
**Refs:** R2, R3
**Files:** Create `app/src/main/java/cc/floresta/aodtoggle/system/SystemAodSettings.kt`, `app/src/androidTest/java/cc/floresta/aodtoggle/system/SystemAodSettingsTest.kt`.
- [ ] `AOD_KEY = "ambient_enabled"` em `Settings.Global`; `read()` nulo em `SettingNotFoundException` **e** em `SecurityException` (leitura negada), cada caso com sua linha de log; `hasWritePermission()` via `checkSelfPermission`; `write()` captura `SecurityException` e registra.
- [ ] Fábrica que liga o núcleo ao `Log.w("AodToggle", …)`.
- [ ] **Teste instrumentado primeiro** (`app/src/androidTest/java/cc/floresta/aodtoggle/system/SystemAodSettingsTest.kt`): concede `WRITE_SECURE_SETTINGS` ao próprio pacote via `UiAutomation.executeShellCommand("pm grant …")`; com a concessão, `hasWritePermission()` é verdadeiro, `read()` devolve 0 ou 1, `write()` do oposto é relido, e o valor original é restaurado no `@After`. **O teste não revoga**: revogar a permissão do próprio pacote pode matar o processo da instrumentação, e a queda seria lida como falha da premissa 1. O caso revogado é verificado na lista manual (R3, R6, R8).
- [ ] Rodar `./gradlew connectedDebugAndroidTest` no relógio. **Só uma falha de asserção com a concessão feita** (leitura ou escrita negada ao app) para a execução e leva à reabertura da spec (premissa 1); erro de arnês (conexão, instalação) não conta.

### Task 4: Arte "AOD" e ícone de lançador
**Refs:** R1, R7
**Visual:** sim
**Files:** Create `app/src/main/res/drawable/aod_text.xml`, `app/src/main/res/mipmap-anydpi/ic_launcher.xml` (+ camadas), `app/src/main/java/cc/floresta/aodtoggle/system/AodImage.kt`.
- [ ] Vector do texto "AOD" (branco, para tint); `AodImage` rasteriza tingido → `Icon`.
- [ ] Ícone adaptativo: vector âmbar sobre fundo escuro.

### Task 5: Serviço da complication
**Refs:** R1, R2, R3
**Visual:** sim
**Files:** Create `app/src/main/java/cc/floresta/aodtoggle/complication/AodComplicationService.kt`; Modify `AndroidManifest.xml`.
- [ ] `onComplicationRequest` → `SmallImageComplicationData` (`ICON`) com a imagem e o `contentDescription` do estado atual; `getPreviewData` → estado desligado.
- [ ] Manifesto: permissão de bind, intent-filter de update request, `SUPPORTED_TYPES = SMALL_IMAGE`, `UPDATE_PERIOD_SECONDS = 0`.

### Task 6: Toque na complication
**Refs:** R4, R5, R6
**Files:** Create `app/src/main/java/cc/floresta/aodtoggle/complication/ToggleReceiver.kt`; Modify `AodComplicationService.kt`, `AndroidManifest.xml`.
- [ ] Receiver não exportado: `toggle()` + `requestUpdateAll()`.
- [ ] `tapAction` = `PendingIntent.getBroadcast` explícito e `FLAG_IMMUTABLE`.

### Task 7: Gatilho
**Refs:** R7, R8
**Visual:** sim
**Files:** Create `app/src/main/java/cc/floresta/aodtoggle/trigger/TriggerActivity.kt`, `app/src/main/res/layout/activity_trigger.xml`, `app/src/main/res/values/strings.xml`, tema; Modify `AndroidManifest.xml`.
- [ ] Activity de lançador (`noHistory`, `excludeFromRecents`): `toggle()`, mostra imagem + texto do estado devolvido, `requestUpdateAll()`, `finish()` em 1000 ms.

### Task 8: README
**Refs:** R11
**Files:** Create `README.md`.
- [ ] Build (JDK 17, Android SDK, keystore em `~/.gradle/gradle.properties`), pareamento/conexão adb por Wi-Fi (manter a tela de depuração aberta; porta muda), `pm grant`, instalação, mapeamento do gatilho a um botão — tudo para o **release** `cc.floresta.aodtoggle` (rótulo "AOD"); o debug (`cc.floresta.aodtoggle.debug`, "AOD (debug)") só aparece na seção de desenvolvimento.

### Task 9: Lista de verificação manual
**Refs:** R10
**Files:** Create `docs/manual-checklist.md`.
- [ ] Cabeçalho: a lista roda sobre o **release** `cc.floresta.aodtoggle` (rótulo "AOD"); o debug é desinstalado antes, para haver um só provedor e um só app "AOD" no relógio.
- [ ] **Primeiro item:** concessão `pm grant` ao release e leitura/escrita da chave pelo app (risco da spec).
- [ ] Itens para R1–R8 e N1, N4–N8, em dois mostradores (Gravity + o segundo achado), com colunas resultado/observação, prontos para copiar no `evidence.md`.

<!-- Tasks 10–14: reabertura do Gate 1 em 2026-10-25 (spec reaprovada). As Tasks 1–9 ficam como foram executadas. -->

### Task 10: Mapeamento da tela do gatilho no núcleo (test-first)
**Refs:** R7, R8, R9
**Files:** Modify `app/src/main/java/cc/floresta/aodtoggle/core/*.kt`, `app/src/test/java/cc/floresta/aodtoggle/core/*Test.kt`.
- [ ] Testes primeiro: `triggerViewOf(On)` = marcado, habilitado, sem texto; `Off` = desmarcado, habilitado, sem texto; `Unavailable(NO_PERMISSION)` e `Unavailable(KEY_MISSING)` = desmarcado, desabilitado, com texto.
- [ ] Implementar `TriggerView` e `triggerViewOf` até verde.

### Task 11: Arte N1 e ícone da prévia nº 3
**Refs:** R1
**Visual:** sim
**Files:** Modify `app/src/main/res/drawable/aod_text.xml`, `app/src/main/res/drawable/ic_launcher_foreground.xml`, `app/src/main/res/mipmap-anydpi/ic_launcher.xml`, `ic_launcher_round.xml`; remover `values/ic_launcher_background.xml` se ficar sem uso.
- [ ] `aod_text.xml` com a arte N1 (valores de "Interfaces & integration points"), de uma cor, sem mudar `AodImage`.
- [ ] Ícone adaptativo: fundo `@android:color/transparent`; primeiro plano com aro `#3A3A3A` e arte N1 âmbar nas proporções da prévia nº 3, dentro do círculo visível; monocromático = primeiro plano.

### Task 12: Nome no seletor e atualização periódica
**Refs:** R12, N6, N7
**Visual:** sim
**Files:** Modify `AndroidManifest.xml`, `app/src/main/res/values/strings.xml`, `app/src/debug/res/values/strings.xml`.
- [ ] Serviço com `android:label="@string/complication_name"`: "AOD Toggle" no main, "AOD Toggle (debug)" no debug.
- [ ] `UPDATE_PERIOD_SECONDS = 300`.

### Task 13: Tela do gatilho com interruptor
**Refs:** R7, R8
**Visual:** sim
**Files:** Modify `app/src/main/java/cc/floresta/aodtoggle/trigger/TriggerActivity.kt`, `app/src/main/res/layout/activity_trigger.xml`, `AndroidManifest.xml`, `app/src/main/res/values/strings.xml`.
- [ ] Layout: imagem em cima, `Switch` rotulado "AOD" abaixo, texto "AOD unavailable" visível só quando indisponível; centrado para tela redonda.
- [ ] Activity: `singleTop`; alterna em `onCreate` sem estado salvo e em `onNewIntent`; clique no `Switch` alterna; `render` via `triggerViewOf`; `requestUpdateAll()` após cada alternância; sem `finish()` agendado.

### Task 14: README e lista manual da reabertura
**Refs:** R10, R11
**Files:** Modify `README.md`, `docs/manual-checklist.md`.
- [ ] README: a tela do gatilho (alterna ao abrir, interruptor, sai com o botão) e o nome "AOD Toggle" no seletor; o aviso de bateria da OnePlus ao adicionar a complication.
- [ ] Lista — reescrever o "Passo"/"Esperado" dos itens existentes para os requisitos reaprovados: F1 (o seletor lista "AOD Toggle" sob o cabeçalho "AOD" — R12; arte N1), F2 (N7: com a tela ligada, a complication acompanha uma mudança feita em Configurações em ≤ ~5 min; cronometrar), T3 (R7: cada pressão alterna e mostra imagem + interruptor no novo estado; a tela fica aberta; tocar no interruptor alterna de novo; pressionar com a tela aberta alterna de novo; apagar a tela a fecha), T4 (R8: imagem cinza, "AOD unavailable", interruptor desabilitado que não responde; a tela fica aberta; a chave não muda), F9 (N1 também do toque no interruptor).
- [ ] Lista — itens novos: N6 (`dumpsys batterystats --reset`, ~1 h **fora do carregador** com a complication no mostrador ativo → ≤ ~12 acionamentos/h do serviço e CPU desprezível; ~1 h sem ela em mostrador nenhum → 0; reconectar o adb antes de cada leitura). Retirar N8/T5. Atualizar a tabela de cobertura (R7, R8, R12, N1, N6, N7).
- [ ] Manter a tela ligada na medida de N7: `adb shell svc power stayon true` (ou "Permanecer ativo" nas opções do desenvolvedor) e, na restauração final, `adb shell svc power stayon false`.

<!-- Task 15: segunda reabertura do Gate 1 em 2026-10-25 (aro na complication; spec reaprovada). -->

### Task 15: Aro na arte da complication
**Refs:** R1
**Visual:** sim
**Files:** Modify `app/src/main/res/drawable/aod_text.xml`.
- [ ] Envolver a arte N1 num grupo com escala 0,62 em torno de (50,50) e acrescentar o aro (traço 6, raio 47, centro 50,50), tudo branco para o tint; sem mudar `AodImage` nem o ícone.
- [ ] Conferir com uma renderização de prévia (SVG equivalente → PNG) que o aro não é cortado pelo quadro de 100.

<!-- Task 16: terceira reabertura do Gate 1 em 2026-10-25 (aro retirado da complication; spec reaprovada). -->

### Task 16: Retirar o aro da arte da complication
**Refs:** R1
**Visual:** sim
**Files:** Modify `app/src/main/res/drawable/aod_text.xml`, `docs/manual-checklist.md`.
- [ ] `aod_text.xml` volta ao conteúdo de antes da Task 15 (arte N1 em escala 1, sem aro); `AodImage` e o ícone não mudam.
- [ ] Item F1 da lista manual: "arte N1 (O em forma de relógio), sem aro, em branco, âmbar e cinza (R1)".
