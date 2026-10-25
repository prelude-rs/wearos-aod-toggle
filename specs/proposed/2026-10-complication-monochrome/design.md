# Design: Complication do AOD em imagem monocromática, na cor do tema do mostrador

Change-ID: 2026-10-complication-monochrome
Status: Draft            <!-- Approved only after consistency-gate PASS + human review -->
Spec: ./spec.md

## Approach summary

A complication passa a declarar `MONOCHROMATIC_IMAGE` além de `SMALL_IMAGE` e responde no tipo que o
pedido traz. O núcleo ganha um mapeamento puro estado → **forma monocromática** (sólido, vazado, tarja),
testado na JVM. Cada forma é um vector drawable estático, de uma cor só (branco), entregue ao mostrador
como `Icon` de recurso, que o próprio mostrador pinta com a cor do tema; o sólido reaproveita a arte de
hoje (`aod_text`). O `SMALL_IMAGE` não muda. Abordagens consideradas: (A) três vectors estáticos —
escolhida pelo autor: arte toda em XML, nítida em qualquer tamanho, sem código de desenho novo; (B)
desenhar em código (bitmap + `Canvas`, folga por `CLEAR`) — mais código Android sem teste de unidade e
arte dividida entre XML e código; (C) uma arte só variando a opacidade — descartada: vazado e tarja não
saem de opacidade.

## Stack & dependencies

Sem dependência nova. `MonochromaticImage` e `MonochromaticImageComplicationData` já vêm de
`androidx.wear.watchface:watchface-complications-data-source-ktx` (a mesma biblioteca de hoje). Stack,
SDKs e lint como no SoT § Stack.

## Data modeling

Sem persistência. No núcleo (`rs.prelude.aodtoggle.core`, Kotlin puro):

```kotlin
enum class MonochromeForm { SOLID, HOLLOW, STRUCK }

fun monochromeFormOf(state: AodState): MonochromeForm = when (state) {
    AodState.On -> MonochromeForm.SOLID
    AodState.Off -> MonochromeForm.HOLLOW
    is AodState.Unavailable -> MonochromeForm.STRUCK
}
```

`presentationOf` (cor e rótulo), `tapActionFor` e `triggerViewOf` não mudam; o rótulo de
`presentationOf` continua sendo o `contentDescription` nos dois tipos.

## Interfaces & integration points

| Peça | Mudança |
|---|---|
| `core/MonochromeForm.kt` (novo) | `MonochromeForm` e `monochromeFormOf` acima. |
| `res/drawable/aod_mono_hollow.xml` (novo) | Desligado (R3): viewport 100×100, tudo branco. "A" e "D" com os caminhos de `aod_text` e os mesmos deslocamentos (A −6, D +7,5), **só contorno**: `strokeColor` branco, `strokeWidth` 2,2, `strokeLineJoin` round, sem `fillColor` (o contador do A também vira contorno). Relógio com a geometria de `aod_text` (anel de raio 16,95 e traço 3,6; ponteiros; ponto central), cada caminho com `strokeAlpha`/`fillAlpha` 0,6 — o vector não tem alfa de grupo; onde ponteiros e ponto se sobrepõem no centro o alfa compõe (~0,84), efeito aceito. |
| `res/drawable/aod_mono_struck.xml` (novo) | Indisponível (R4): o mesmo desenho do `aod_mono_hollow`, dentro de um `<group>` com `<clip-path>` que é o quadro 0–100 (sentido horário) **menos** a faixa da folga (polígono no sentido anti-horário, regra de preenchimento não-zero), mais a **tarja**: linha de (14,76) a (88,24), `strokeWidth` 3,6, `strokeLineCap` round, fora do grupo recortado. A faixa da folga é o retângulo de largura 9 centrado nessa linha (meia-largura 4,5 para cada lado), estendido 4,5 além de cada ponta. Valores da prévia "tarja com folga" aprovada pelo autor. |
| `res/drawable/aod_text.xml` | Sem mudança; é a forma `SOLID` (R2). |
| `system/AodImage.kt` | Novo `fun monochromeIcon(context: Context, form: MonochromeForm): Icon` = `Icon.createWithResource(context, <recurso da forma>)` (SOLID → `aod_text`, HOLLOW → `aod_mono_hollow`, STRUCK → `aod_mono_struck`). O `icon(...)` de hoje (bitmap tingido) continua para o `SMALL_IMAGE` e o gatilho. |
| `complication/AodComplicationService.kt` | `onComplicationRequest` decide por `request.complicationType`: `SMALL_IMAGE` → como hoje; `MONOCHROMATIC_IMAGE` → `MonochromaticImageComplicationData.Builder(MonochromaticImage.Builder(monochromeIcon(...)).build(), contentDescription)` com o mesmo `tapAction` (`tapActionFor(state)`); outro tipo → `null`. `getPreviewData` responde aos dois tipos com o estado desligado. O cálculo do estado e do `PendingIntent` é o mesmo nos dois tipos (R6). |
| `AndroidManifest.xml` | `SUPPORTED_TYPES = "MONOCHROMATIC_IMAGE,SMALL_IMAGE"`. A ordem nesta lista não decide nada: quem escolhe é a lista do slot do mostrador (spec, Contexto). `UPDATE_PERIOD_SECONDS` continua 300. |
| `ComplicationTapReceiver`, `TriggerActivity`, ícone do app | Sem mudança. |

## Seams sob teste

| Seam (onde) | Existente / novo | O que se observa através dele | Req IDs |
|---|---|---|---|
| API pública do núcleo `rs.prelude.aodtoggle.core` (`monochromeFormOf`, ao lado de `presentationOf`/`tapActionFor`/`triggerViewOf`) | existente | A forma de cada estado e de cada causa de indisponível | R2, R3, R4, R7 |
| O relógio real (lista manual) | existente | Tipo escolhido por mostrador, cor do tema, formas visíveis, toque, atualização, latência, logcat, energia | R1–R6, R8, N1, N4–N6 |

**Justificativa dos seams novos:** nenhum seam novo.

## Superfície heurística: código medido

N/A — a spec declara que não há superfície heurística.

## Dev-run premise

- Launch: com o relógio conectado via adb (README), `./gradlew installDebug`, depois
  `adb shell pm grant rs.prelude.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`; no editor do
  mostrador "Chic", recolocar a complication "AOD Toggle (debug)" num slot de imagem (o slot escolhe a
  monocromática), e no Gravity num slot que use o `SMALL_IMAGE`. Indisponível: `adb shell pm revoke` da
  mesma permissão.
- Mock/dev-flag strategy: nenhuma — sem backend; o único sistema externo é o do relógio, exercido de verdade.
- Signed exception (Gate 1.5 only): none

## Requirement → design map

| Req ID | Design element that satisfies it |
|--------|----------------------------------|
| R1 | Manifesto declara os dois tipos; `onComplicationRequest` responde no tipo pedido |
| R2 | `monochromeFormOf(On) = SOLID` → `aod_text` como `Icon` de recurso |
| R3 | `monochromeFormOf(Off) = HOLLOW` → `aod_mono_hollow` |
| R4 | `monochromeFormOf(Unavailable) = STRUCK` → `aod_mono_struck` (clip-path da folga + tarja) |
| R5 | Ramo `SMALL_IMAGE` intocado (`AodImage.icon` e `presentationOf`) — preservação |
| R6 | Mesmo estado e mesmo `tapActionFor`/`PendingIntent` nos dois ramos; período no manifesto inalterado |
| R7 | Testes JUnit 4 de `monochromeFormOf` |
| R8 | `docs/manual-checklist.md` atualizada e executada; resultados no `evidence.md` |

## NFR mechanisms

| NFR | Por construção | Por teste |
|---|---|---|
| N1 | Mesmo caminho do toque de hoje (broadcast → escrita → `requestUpdateAll`); o `Icon` de recurso evita rasterizar no app. | Item da lista no mostrador monocromático. |
| N2 | — | — |
| N3 | Sem dados de tenant, sem rede. | Coberto por N4. |
| N4 | Nenhuma permissão nova no manifesto. | `aapt dump permissions` do release. |
| N5 | O log continua só no núcleo/adaptador, nas falhas; o ramo novo não registra. | Item da lista (`logcat -s AodToggle`). |
| N6 | Nenhum serviço, alarme ou job novo; o mesmo período de 300 s. | `dumpsys alarm`/`jobscheduler`; `batterystats` com a monocromática num mostrador (~1 h). |

## Failure modes & rollout

| Falha | Degradação |
|---|---|
| Mostrador ignora o alfa da imagem monocromática | Relógio do desligado sai cheio; desligado ainda difere do ligado pelas letras vazadas (risco da spec). |
| `clip-path` do vector não abre a folga como esperado | A tarja aparece sem folga (como a "tarja simples" da prévia); visível na revisão visual — conserto no XML. |
| Slot configurado antes da atualização mantém o tipo antigo | Continua colorido até recolocar a complication (risco da spec; lista e README orientam). |
| Pedido de um tipo não declarado | `null` (como hoje). |

Rollout: sideload do release (`adb install -r`), mesma assinatura — mantém a permissão concedida; os
mostradores podem precisar que a complication seja recolocada para trocar de tipo.

## Decisions log

| Decisão | Opção não tomada | Por quê | ADR? |
|---|---|---|---|
| Três vectors estáticos | Desenhar em código; opacidade só | Escolha do autor; arte toda em XML, nítida, sem código de desenho | Não — fácil de reverter. |
| `Icon` de recurso na monocromática | Bitmap rasterizado (como o `SMALL_IMAGE`) | O mostrador pinta o recurso; nítido em qualquer tamanho; nada a tingir no app | Não. |
| Folga por `clip-path` com sentido de traçado | Recortar os caminhos geometricamente | Uma faixa só, valores da prévia; sem recalcular a arte | Não. |
| Alfa 0,6 por caminho do relógio | Alfa de grupo | O vector não tem alfa de grupo; sobreposição no centro aceita | Não. |
| `MonochromeForm` no núcleo | Decidir a forma no serviço | Mesmo padrão de `presentationOf`/`triggerViewOf`; testável na JVM (R7) | Não. |

## Assumptions

Nenhuma além das que a spec já registra (Contexto e Riscos).

## Global Constraints

- Pacote `rs.prelude.aodtoggle`; `minSdk`/`targetSdk` 34, `compileSdk` 36; JDK 17; sem dependência nova.
- Tipos declarados: `MONOCHROMATIC_IMAGE,SMALL_IMAGE`; `UPDATE_PERIOD_SECONDS` 300.
- Formas monocromáticas: ligado = `aod_text` (sólido); desligado = A e D só contorno (traço 2,2, junção
  round) + relógio a alfa 0,6; indisponível = o desligado recortado pela folga (faixa de largura 9 em
  torno da linha (14,76)–(88,24), estendida 4,5 além das pontas) + tarja nessa linha, traço 3,6, ponta round.
- Geometria herdada de `aod_text`: A −6, D +7,5; anel raio 16,95, traço 3,6, centro 51,50; ponteiros
  35°/8,9/4,05 e 270°/13,3/3,04; ponto central 2,15.
- Imagens monocromáticas em branco puro, para o mostrador pintar; `SMALL_IMAGE` e gatilho inalterados.
- Única permissão: `android.permission.WRITE_SECURE_SETTINGS`; tag de log `AodToggle`, só em falha.

## Review Focus

- A folga do `clip-path` realmente transparente no relógio (sentido de traçado e regra não-zero) — Task 2.
- O ramo `MONOCHROMATIC_IMAGE` usa o mesmo estado e o mesmo `tapAction` do `SMALL_IMAGE` (R6) — Task 3.
- `getPreviewData` dos dois tipos (o seletor mostra a prévia monocromática na cor do tema) — Task 3.
- Legibilidade das letras vazadas e do relógio a 60% no tamanho do slot — Task 2 (revisão visual).

## Decomposição

**Justificativa de dimensionamento:** N/A

**Execução:** subagent-driven

### Task 1: Forma monocromática no núcleo (test-first)
**Refs:** R2, R3, R4, R7
**Files:** Create `app/src/main/java/rs/prelude/aodtoggle/core/MonochromeForm.kt`, `app/src/test/java/rs/prelude/aodtoggle/core/MonochromeFormTest.kt`.
- [ ] Testes primeiro: `On` → `SOLID`; `Off` → `HOLLOW`; `Unavailable(NO_PERMISSION)` e `Unavailable(KEY_MISSING)` → `STRUCK`.
- [ ] Implementar `MonochromeForm` e `monochromeFormOf` até verde.

### Task 2: Vectors das formas vazada e com tarja
**Refs:** R3, R4
**Visual:** sim
**Files:** Create `app/src/main/res/drawable/aod_mono_hollow.xml`, `app/src/main/res/drawable/aod_mono_struck.xml`.
- [ ] `aod_mono_hollow` com os valores de "Interfaces & integration points" e "Global Constraints".
- [ ] `aod_mono_struck` = o desenho do vazado dentro do `clip-path` da folga + a tarja.
- [ ] Prévia: SVG equivalente renderizado em PNG (como nas tasks de arte anteriores), anexado ao relatório; a verificação real é a revisão visual.

### Task 3: Complication responde no tipo monocromático
**Refs:** R1, R2, R5, R6
**Visual:** sim
**Files:** Modify `app/src/main/java/rs/prelude/aodtoggle/system/AodImage.kt`, `app/src/main/java/rs/prelude/aodtoggle/complication/AodComplicationService.kt`, `app/src/main/AndroidManifest.xml`.
- [ ] `AodImage.monochromeIcon(context, form)` → `Icon` de recurso por forma.
- [ ] `onComplicationRequest` e `getPreviewData` respondem a `MONOCHROMATIC_IMAGE` e `SMALL_IMAGE` (este sem mudança), com o mesmo estado e `tapAction`.
- [ ] Manifesto: `SUPPORTED_TYPES = "MONOCHROMATIC_IMAGE,SMALL_IMAGE"`.

### Task 4: README e lista manual
**Refs:** R8
**Files:** Modify `README.md`, `docs/manual-checklist.md`.
- [ ] README: a complication aparece na cor do tema nos mostradores que preferem a monocromática (ligado sólido, desligado vazado, indisponível com tarja); recolocar a complication para trocar de tipo.
- [ ] Lista: ler por adb a lista de tipos dos slots do Gravity e do Chic e registrar o tipo usado; itens para R1–R6, N1, N5, N6 no mostrador monocromático e preservação do `SMALL_IMAGE` (R5) num mostrador que o use; tabela de cobertura.
