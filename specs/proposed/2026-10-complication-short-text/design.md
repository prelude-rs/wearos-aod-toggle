# Design: Complication do AOD em texto curto (`SHORT_TEXT`), com o relógio e "AOD"/"OFF"/"---"

Change-ID: 2026-10-complication-short-text
Status: Draft
Spec: ./spec.md

## Approach summary

A complication passa a declarar `SHORT_TEXT` antes dos tipos de hoje (`ICON` = imagem monocromática, e
`SMALL_IMAGE`) e responde no tipo que o pedido traz. O núcleo ganha um mapeamento puro estado → **vista do
texto curto** (texto e forma do ícone), testado na JVM. O ícone é o relógio da arte "AOD" (o "O": anel,
ponteiros, ponto) recortado num vector próprio, em duas versões — sólido e esmaecido a 60% — rasterizado
pelo app num bitmap branco (o mesmo caminho da imagem monocromática) e entregue como `Icon` de bitmap, que
o mostrador pinta com a cor do tema. A imagem monocromática e o `SMALL_IMAGE` não mudam.

Abordagens consideradas: (A) vectors do relógio + bitmap branco + mapeamento no núcleo — escolhida pelo
autor; (B) reaproveitar `monochromeFormOf` e os vectors `aod_mono_*` — descartada: o ícone do texto curto é
só o relógio, sem A/D e sem tarja; (C) ícone como `Icon` de recurso — funcionou no experimento, mas
descartado pela mesma razão da change anterior (não depender de o mostrador carregar recurso de outro
pacote).

**Protótipo medido (experimento descartável de 2026-10-25, cópia do app fora do repositório, instalada como
debug no OnePlus Watch 3):** `ShortTextComplicationData` com texto e `MonochromaticImage` do relógio
(vector de viewport 40×40, o "O" de `aod_text` deslocado por −31,−30). Resultado: no Chic, o relógio em cima
na cor do tema e o texto embaixo em branco, com a borda fina e a fonte das vizinhas; no Gravity, o mesmo
sobre o disco cinza. `dumpsys` do mostrador: `3=ShortTextComplicationData` do
`rs.prelude.aodtoggle.debug` nos dois. O anel (`RANGED_VALUE`) foi testado e descartado (spec, Contexto).

## Stack & dependencies

Sem dependência nova. `ShortTextComplicationData` vem de
`androidx.wear.watchface:watchface-complications-data-source-ktx` (a mesma biblioteca de hoje). Stack, SDKs e
lint como no SoT § Stack.

## Data modeling

Sem persistência. No núcleo (`rs.prelude.aodtoggle.core`, Kotlin puro):

```kotlin
enum class ClockIcon { SOLID, DIM }

data class ShortTextView(
    val text: String,
    val icon: ClockIcon,
)

fun shortTextViewOf(state: AodState): ShortTextView = when (state) {
    AodState.On -> ShortTextView("AOD", ClockIcon.SOLID)
    AodState.Off -> ShortTextView("OFF", ClockIcon.DIM)
    is AodState.Unavailable -> ShortTextView("---", ClockIcon.DIM)
}
```

Os três textos são literais do protocolo visual (não traduzíveis, não recursos de string): "AOD", "OFF",
"---". O `contentDescription` continua sendo o rótulo de `presentationOf` nos três tipos.

## Interfaces & integration points

| Peça | Mudança |
|---|---|
| `core/ShortTextView.kt` (novo) | `ClockIcon`, `ShortTextView` e `shortTextViewOf` acima. |
| `res/drawable/aod_clock.xml` (novo) | Ícone sólido (R2): viewport 40×40, `width`/`height` 24dp, um `<group>` com `translateX` −31 e `translateY` −30 contendo os quatro caminhos do relógio de `aod_text` sem alteração — anel (centro 51,50, raio 16,95, traço 3,6), ponteiro de horas (35°, 8,9, traço 4,05, ponta round), ponteiro de minutos (270°, 13,3, traço 3,04, ponta round), ponto central (raio 2,15). Tudo branco `#FFFFFFFF`. |
| `res/drawable/aod_clock_dim.xml` (novo) | Ícone esmaecido (R3, R4): o mesmo desenho de `aod_clock`, cada caminho com `strokeAlpha`/`fillAlpha` 0,6 (o vector não tem alfa de grupo; a sobreposição no centro compõe ~0,94, como no `aod_mono_hollow`). |
| `res/drawable/aod_text.xml`, `aod_mono_*.xml` | Sem mudança. |
| `system/AodImage.kt` | Novo `fun clockIcon(context: Context, icon: ClockIcon): Icon`: rasteriza `aod_clock` (SOLID) ou `aod_clock_dim` (DIM) com o `rasterize` existente, sem tint (branco, alfa preservado), em bitmap de `AOD_IMAGE_SIZE_PX`, e devolve `Icon.createWithBitmap`. |
| `complication/AodComplicationService.kt` | `dataFor` ganha o ramo `ComplicationType.SHORT_TEXT` → `ShortTextComplicationData.Builder(PlainComplicationText(view.text), contentDescription).setMonochromaticImage(MonochromaticImage.Builder(clockIcon(...)).build()).setTapAction(tapAction)`, com `view = shortTextViewOf(state)`; o estado e o `tapAction` são os mesmos dos outros ramos (R6). `getPreviewData` passa a responder também ao texto curto (estado desligado: "OFF"), pelo mesmo `dataFor`. Sem título. |
| `AndroidManifest.xml` | `SUPPORTED_TYPES = "SHORT_TEXT,ICON,SMALL_IMAGE"`. A ordem não decide nada: decide a lista do slot (spec, Contexto). `UPDATE_PERIOD_SECONDS` continua 300. |
| `ComplicationTapReceiver`, `TriggerActivity`, ícone do app | Sem mudança. |

## Seams sob teste

| Seam (onde) | Existente / novo | O que se observa através dele | Req IDs |
|---|---|---|---|
| API pública do núcleo `rs.prelude.aodtoggle.core` (`shortTextViewOf`, ao lado de `presentationOf`/`monochromeFormOf`/`tapActionFor`/`triggerViewOf`) | existente | O texto e a forma do ícone de cada estado e de cada causa de indisponível; as cores (`presentationOf`) e as formas (`monochromeFormOf`) de hoje seguem verdes | R2, R3, R4, R5, R7 |
| O relógio real (lista manual) | existente | Tipo escolhido por mostrador, texto e ícone visíveis, toque, atualização, latência, logcat; a imagem monocromática e o `SMALL_IMAGE` como antes onde usados | R1–R6, R8, N1, N4–N6 |

**Justificativa dos seams novos:** nenhum seam novo.

## Superfície heurística: código medido

N/A — a spec declara que não há superfície heurística.

## Dev-run premise

- Launch: com o relógio conectado via adb (README), `./gradlew installDebug`, depois
  `adb shell pm grant rs.prelude.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`; no editor do
  Gravity e do Chic, remover e recolocar a complication "AOD Toggle (debug)" num dos slots 1–3 (pela lista
  lida, o slot escolhe o texto curto). Indisponível: `adb shell pm revoke` da mesma permissão.
- Mock/dev-flag strategy: nenhuma — sem backend; o único sistema externo é o do relógio, exercido de verdade.
- Signed exception (Gate 1.5 only): none

## Requirement → design map

| Req ID | Design element that satisfies it |
|--------|----------------------------------|
| R1 | Manifesto declara `SHORT_TEXT,ICON,SMALL_IMAGE`; `dataFor` responde no tipo pedido |
| R2 | `shortTextViewOf(On) = ("AOD", SOLID)` → `aod_clock` rasterizado em bitmap branco (`clockIcon`) |
| R3 | `shortTextViewOf(Off) = ("OFF", DIM)` → `aod_clock_dim` |
| R4 | `shortTextViewOf(Unavailable) = ("---", DIM)` → `aod_clock_dim` |
| R5 | Ramos `MONOCHROMATIC_IMAGE` e `SMALL_IMAGE` intocados — preservação |
| R6 | Mesmo estado e mesmo `tapActionFor`/`PendingIntent` nos três ramos; período no manifesto inalterado (`UPDATE_PERIOD_SECONDS=300`, conferido no APK) e item da lista para a atualização periódica no texto curto |
| R7 | Testes JUnit 4 de `shortTextViewOf` |
| R8 | `docs/manual-checklist.md` atualizada e executada; resultados no `evidence.md` |

## NFR mechanisms

| NFR | Por construção | Por teste |
|---|---|---|
| N1 | Mesmo caminho do toque de hoje (broadcast → escrita → `requestUpdateAll`); a rasterização é a mesma da imagem monocromática. | Item da lista. |
| N2 | — | — |
| N3 | Sem dados de tenant, sem rede. | Coberto por N4. |
| N4 | Nenhuma permissão nova no manifesto. | `aapt dump permissions` do release. |
| N5 | O ramo novo não registra; o log segue só nas falhas. | Item da lista (`logcat -s AodToggle`). |
| N6 | Nenhum serviço, alarme ou job novo; o mesmo período de 300 s. | `dumpsys alarm`/`jobscheduler`. |

## Failure modes & rollout

| Falha | Degradação |
|---|---|
| Mostrador desenha o texto curto sem o ícone | O estado continua legível pelo texto ("AOD"/"OFF"/"---"). |
| Mostrador corta o texto | Textos de 3 caracteres, dentro do limite de ~7 do tipo; verificado na lista. |
| Slot configurado antes da atualização mantém o tipo antigo | Continua como imagem até recolocar a complication (risco da spec; lista e README orientam). |
| Pedido de um tipo não declarado | `null` (como hoje). |

Rollout: sideload do release (`adb install -r`), mesma assinatura — mantém a permissão concedida; os
mostradores precisam que a complication seja recolocada para trocar de tipo.

## Decisions log

| Decisão | Opção não tomada | Por quê | ADR? |
|---|---|---|---|
| Texto curto em vez do anel de valor | `RANGED_VALUE` | Experimento: o anel genérico mostra uma coisa só, ignora cor/opacidade e fica ruim no Chic (spec, Contexto). Decisão do autor. | Não. |
| Ícone em bitmap branco | `Icon` de recurso | Mesma razão da change anterior; o experimento com recurso funcionou, então o bitmap é a escolha conservadora. | Não. |
| Vectors só do relógio (viewport 40) | Reaproveitar `aod_text` inteiro | A spec pede só o relógio; o recorte foi o do protótipo. | Não. |
| `ShortTextView` no núcleo | Decidir no serviço | Mesmo padrão de `presentationOf`/`monochromeFormOf`; testável na JVM (R7). | Não. |
| Sem título | Título com o estado | Fora do escopo da spec. | Não. |

## Assumptions

- **Alfa do ícone esmaecido preservado no texto curto.** O protótipo mediu o relógio sólido, como `Icon` de
  recurso; o esmaecido em bitmap branco não foi medido no texto curto. Base: o ícone do texto curto é uma
  `MonochromaticImage`, o mesmo tipo da imagem monocromática, cujo relógio a alfa 0,6 apareceu esmaecido no
  Gravity e no Chic (M3 da change anterior, em bitmap branco). Se o mostrador ignorar o alfa no ícone do
  texto curto, ligado e desligado ainda se distinguem pelo texto ("AOD"/"OFF") — risco 2 da spec, aceito.
  Confirmado na revisão visual (Task 2).

## Global Constraints

- Pacote `rs.prelude.aodtoggle`; `minSdk`/`targetSdk` 34, `compileSdk` 36; JDK 17; sem dependência nova.
- Tipos declarados: `SHORT_TEXT,ICON,SMALL_IMAGE` (`ICON` é o nome, no manifesto, do tipo `MONOCHROMATIC_IMAGE`); `UPDATE_PERIOD_SECONDS` 300.
- Texto curto: ligado = "AOD" + relógio sólido; desligado = "OFF" + relógio a alfa 0,6; indisponível = "---" + relógio a alfa 0,6. Sem título.
- Relógio: viewport 40×40, `translate(−31, −30)` sobre a geometria de `aod_text` — anel centro 51,50, raio 16,95, traço 3,6; ponteiros 35°/8,9/4,05 e 270°/13,3/3,04, ponta round; ponto central 2,15. Branco puro.
- Imagem monocromática, `SMALL_IMAGE` e gatilho inalterados.
- Única permissão: `android.permission.WRITE_SECURE_SETTINGS`; tag de log `AodToggle`, só em falha.

## Review Focus

- O ramo `SHORT_TEXT` usa o mesmo estado e o mesmo `tapAction` dos outros ramos (R6) — Task 3.
- `getPreviewData` do texto curto (o seletor mostra "OFF") — Task 3.
- O relógio esmaecido legível no tamanho do ícone e distinto do sólido — Task 2 (revisão visual).
- O manifesto declara `SHORT_TEXT` com o nome que o sistema reconhece (lição da change anterior: `ICON`) — Task 3, conferido por `aapt2` e pelo `dumpsys` do mostrador.

## Decomposição

**Justificativa de dimensionamento:** N/A

**Execução:** subagent-driven

### Task 1: Vista do texto curto no núcleo (test-first)
**Refs:** R2, R3, R4, R7
**Files:** Create `app/src/main/java/rs/prelude/aodtoggle/core/ShortTextView.kt`, `app/src/test/java/rs/prelude/aodtoggle/core/ShortTextViewTest.kt`.
- [ ] Testes primeiro: `On` → ("AOD", `SOLID`); `Off` → ("OFF", `DIM`); `Unavailable(NO_PERMISSION)` e `Unavailable(KEY_MISSING)` → ("---", `DIM`).
- [ ] Implementar `ClockIcon`, `ShortTextView` e `shortTextViewOf` até verde.

### Task 2: Vectors do relógio sólido e esmaecido
**Refs:** R2, R3, R4
**Visual:** sim
**Files:** Create `app/src/main/res/drawable/aod_clock.xml`, `app/src/main/res/drawable/aod_clock_dim.xml`.
- [ ] `aod_clock` com os valores de "Interfaces & integration points" e "Global Constraints".
- [ ] `aod_clock_dim` = o mesmo desenho com alfa 0,6 por caminho.
- [ ] Prévia: SVG equivalente renderizado em PNG, anexado ao relatório; a verificação real é a revisão visual.

### Task 3: Complication responde em texto curto
**Refs:** R1, R2, R3, R4, R5, R6
**Visual:** sim
**Files:** Modify `app/src/main/java/rs/prelude/aodtoggle/system/AodImage.kt`, `app/src/main/java/rs/prelude/aodtoggle/complication/AodComplicationService.kt`, `app/src/main/AndroidManifest.xml`.
- [ ] `AodImage.clockIcon(context, icon)` → bitmap branco rasterizado do vector do relógio.
- [ ] `dataFor` responde a `SHORT_TEXT` (texto + ícone, mesmo estado e `tapAction`); `getPreviewData` também; os outros ramos sem mudança.
- [ ] Manifesto: `SUPPORTED_TYPES = "SHORT_TEXT,ICON,SMALL_IMAGE"`.

### Task 4: README e lista manual
**Refs:** R8
**Files:** Modify `README.md`, `docs/manual-checklist.md`.
- [ ] README (Risco 1 da spec: slots já configurados mantêm o tipo antigo): nos mostradores que preferem o texto curto, a complication mostra o relógio e "AOD"/"OFF"/"---"; recolocar a complication para trocar de tipo.
- [ ] Lista: ler por adb o tipo usado no Gravity e no Chic; itens para R1–R4, R6 (toque, indisponível + `pm grant`, e a atualização periódica: mudar o AOD em Configurações e ver o texto acompanhar em ≤ ~5 min; `aapt2` do release com `UPDATE_PERIOD_SECONDS=300`), R5 (imagem monocromática/`SMALL_IMAGE` onde usados, ou o fallback dos testes de unidade), N1, N5, N6 no texto curto; tabela de cobertura.
