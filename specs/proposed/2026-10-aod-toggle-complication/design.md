# Design: Complication e gatilho para alternar o AOD no OnePlus Watch 3

Change-ID: 2026-10-aod-toggle-complication
Status: Draft            <!-- Approved only after consistency-gate PASS + human review -->
Spec: ./spec.md

## Approach summary

Um único módulo Android (`app`), Kotlin, sem UI além do retorno de ~1 s do gatilho. O núcleo é Kotlin
puro: um **porto** `AodSettings` (ler o valor, escrever o valor, saber se há permissão) e, sobre ele, a
lógica de estado (ligado / desligado / indisponível), a alternância com releitura e o mapeamento estado →
apresentação (cor + texto). Três bordas Android usam esse núcleo: o serviço da complication
(`SuspendingComplicationDataSourceService`, só `SMALL_IMAGE`), um `BroadcastReceiver` que recebe o toque
na complication e uma `Activity` de lançador (o gatilho). A imagem "AOD" é um único vector drawable,
rasterizado já tingido na cor do estado.

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
| UI do gatilho | Views simples (um layout XML: `ImageView` + `TextView`) | Zero dependência de UI; Compose traria uma árvore grande para uma tela estática. |
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
```

Regra de estado (`AodToggle.current()`): sem permissão → `Unavailable(NO_PERMISSION)`; senão `read()`
nulo → `Unavailable(KEY_MISSING)`; `1` → `On`; qualquer outro valor → `Off`.

Regra de alternância (`AodToggle.toggle()`): avalia `current()`; se indisponível, devolve esse estado
**sem escrever** (R6, R8); senão escreve o oposto (`On` → 0, `Off` → 1), relê e devolve o estado relido
(R5); se o relido é igual ao anterior, registra "escrita sem efeito" (N5).

Apresentação (`presentationOf(state)`): `On` → âmbar `0xFFFFC107` / "AOD on"; `Off` → branco
`0xFFFFFFFF` / "AOD off"; `Unavailable` → cinza `0xFF757575` / "AOD unavailable".

## Interfaces & integration points

| Peça | Pacote | Papel |
|---|---|---|
| `SystemAodSettings` | `cc.floresta.aodtoggle.system` | Implementa o porto: `Settings.Global` `ambient_enabled` (constante `AOD_KEY`, **único ponto** onde a chave aparece — pedido do brief), `checkSelfPermission(WRITE_SECURE_SETTINGS)`. `read()` devolve `null` tanto em `SettingNotFoundException` quanto em `SecurityException` (leitura de chave oculta negada a apps com `targetSdk` ≥ 31), registrando linhas distintas; `write()` captura `SecurityException`. |
| `AodImage` | `cc.floresta.aodtoggle.system` | Rasteriza `R.drawable.aod_text` tingido com `Presentation.tintArgb` num `Bitmap` → `Icon.createWithBitmap`. A cor fica no bitmap, não dependendo de o mostrador respeitar tint de `Icon`. |
| `AodComplicationService` | `cc.floresta.aodtoggle.complication` | `SuspendingComplicationDataSourceService`; tipo suportado só `SMALL_IMAGE` (`SmallImageType.ICON`, que não é recortado como `PHOTO`); `contentDescription` = `Presentation.label`; `tapAction` = `PendingIntent` de broadcast explícito para `ToggleReceiver`; sem imagem ambiente (o mostrador decide); `getPreviewData` devolve o estado `Off`. |
| `ToggleReceiver` | `cc.floresta.aodtoggle.complication` | `BroadcastReceiver` não exportado: `AodToggle.toggle()` e `ComplicationDataSourceUpdateRequester.requestUpdateAll()`. |
| `TriggerActivity` | `cc.floresta.aodtoggle.trigger` | Activity de lançador (`MAIN`/`LAUNCHER`, `noHistory`, `excludeFromRecents`): `toggle()`, mostra imagem + `label`, `requestUpdateAll()`, `finish()` após 1000 ms. |

Manifesto: `<uses-permission android:name="android.permission.WRITE_SECURE_SETTINGS"
tools:ignore="ProtectedPermissions"/>` (única permissão; o `tools:ignore` silencia o erro do lint
`ProtectedPermissions`, porque a concessão vem de `pm grant`); os nós
`<permission>` e `<uses-permission>` de `${applicationId}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, que o
`androidx.core` ≥ 1.9 injeta no manifesto mesclado, são removidos com `tools:node="remove"` (o app não
registra receiver dinâmico). `android:exported`: serviço `true` (o sistema faz o bind), activity de
lançador `true`, receiver `false`. Serviço com `android:permission="com.google.android.wearable.permission.BIND_COMPLICATION_PROVIDER"`,
intent-filter `android.support.wearable.complications.ACTION_COMPLICATION_UPDATE_REQUEST`, meta-data
`SUPPORTED_TYPES = SMALL_IMAGE` e `UPDATE_PERIOD_SECONDS = 0`; `uses-feature android.hardware.type.watch`;
`com.google.android.wearable.standalone = true`. Ícone de lançador: ícone adaptativo com o vector "AOD"
âmbar sobre fundo escuro.

Logs: tag única `AodToggle`, `Log.w` só nos casos de falha (indisponível por permissão, por chave, escrita
sem efeito). O núcleo recebe um `(String) -> Unit` para registrar, para continuar Kotlin puro.

## Seams sob teste

| Seam (onde) | Existente / novo | O que se observa através dele | Req IDs |
|---|---|---|---|
| API pública do núcleo `cc.floresta.aodtoggle.core` (`AodToggle.current()`, `AodToggle.toggle()`, `presentationOf()`), com um `AodSettings` falso | novo | Estado derivado de permissão/valor/chave ausente; escrita feita ou não; estado relido após escrita sem efeito; cor e texto por estado; linha de log por falha | R1, R2, R3, R5, R6, R8, R9, N5 |
| `SystemAodSettings` num teste instrumentado (`connectedDebugAndroidTest`) | novo | O app, com a permissão concedida pelo próprio teste, lê a chave, escreve o oposto, relê o novo valor e restaura o original; `hasWritePermission()` reflete a concessão | R2, R4 |
| O relógio real (lista manual) | existente | Comportamento ponta a ponta: mostrador, Configurações, botão, latência, permissões do APK, logcat, ausência de trabalho em segundo plano | R1–R8, R10, N1, N4–N8 |

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
| R7 | `TriggerActivity` (lançador) + `AodImage` + `label` + `requestUpdateAll()` + `finish()` em 1000 ms |
| R8 | Mesmo caminho de R7 com `toggle()` devolvendo indisponível sem escrever |
| R9 | Testes JUnit 4 do núcleo (`app/src/test`) |
| R10 | `docs/manual-checklist.md`, executada e registrada no `evidence.md` |
| R11 | `README.md` |

## NFR mechanisms

| NFR | Por construção | Por teste |
|---|---|---|
| N1 (≤ 1 s) | Toque → broadcast (sem janela) → escrita síncrona de uma chave → `requestUpdateAll()`; gatilho mostra o resultado assim que `toggle()` retorna. O tempo entre `requestUpdateAll()` e o redesenho é do sistema e do mostrador, não do app (premissa 2). | Lista manual: gravação/cronômetro nos dois mostradores. |
| N2 | — (sem meta) | — |
| N3 | Sem dados de tenant, sem rede. | Coberto por N4. |
| N4 | Manifesto declara só `WRITE_SECURE_SETTINGS` e remove (`tools:node="remove"`) a `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` injetada pelo `androidx.core`; o manifesto mesclado é conferido na Task 1. | `aapt dump permissions` do APK de release, na lista manual e no fechamento da Task 1. |
| N5 | Falhas passam pelo log do núcleo → `Log.w("AodToggle", …)`; caminho feliz não registra. | Testes do núcleo (log chamado só nas falhas) + `adb logcat -s AodToggle` na lista manual. |
| N6 | `UPDATE_PERIOD_SECONDS = 0`; nenhum serviço em primeiro plano, alarme, job ou observer. | `dumpsys alarm` / `dumpsys jobscheduler` na lista manual. |
| N7 | Consequência aceita de N6. | Lista manual registra quando a complication acompanha uma mudança feita em Configurações. |
| N8 | `finish()` agendado em 1000 ms. | Lista manual (cronômetro). |

## Failure modes & rollout

| Falha | Degradação |
|---|---|
| Sem `pm grant` | Complication cinza; gatilho mostra "AOD unavailable" e fecha; log `NO_PERMISSION`. |
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
| Retorno do gatilho com Views | Compose for Wear | Uma tela estática não justifica a árvore de dependências. | Não — fácil de reverter. |
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
- Textos: "AOD on", "AOD off", "AOD unavailable".
- Retorno do gatilho: 1000 ms.
- Tipo de complication: só `SMALL_IMAGE` (`ICON`); `UPDATE_PERIOD_SECONDS = 0`.
- Única permissão pedida: `android.permission.WRITE_SECURE_SETTINGS`.
- Tag de log: `AodToggle`; log só em falha.
- Dependências de runtime: só `watchface-complications-data-source-ktx` e `core-ktx`.
- Nada de keystore, senha ou `local.properties` no repositório.

## Review Focus

- Janela de corrida entre `hasWritePermission()` e `write()` (permissão revogada no meio) — Task 3.
- O mostrador recebe `Icon` de bitmap e não recorta nem retinge — Task 5 (lista manual da Task 9).
- O `PendingIntent` do toque é explícito, imutável e o receiver não é exportado — Task 6.
- O gatilho fecha mesmo se a activity for pausada antes dos 1000 ms (`noHistory`) — Task 7.
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
