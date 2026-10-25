# SOURCE-OF-TRUTH — wearos-aod-toggle

## Estado atual

App "AOD Toggle" para o OnePlus Watch 3 (Wear OS 5, Android 14, API 34), pacote `rs.prelude.aodtoggle`,
instalado por sideload e assinado com a keystore da organização prelude-rs. Repositório:
`git@github.com:prelude-rs/wearos-aod-toggle.git`. O app alterna o AOD escrevendo
`Settings.Global` `ambient_enabled` (1 = ligado), com `WRITE_SECURE_SETTINGS` concedida por `adb shell pm grant`;
é a única permissão que pede.

- **Complication** "AOD Toggle" (no seletor; o app se chama "AOD"), só `SMALL_IMAGE`: a palavra "AOD"
  com o O desenhado como relógio (anel e dois ponteiros), sem aro, branca com o AOD desligado, âmbar
  (`#FFC107`) ligado e cinza (`#757575`) indisponível. Sem a permissão, ou sem a chave no aparelho, aparece
  cinza antes de qualquer toque.
- **Toque na complication:** ligada ou desligada, alterna o AOD e mostra o estado relido do sistema;
  indisponível, só reavalia permissão e chave e redesenha, sem alternar.
- **Gatilho** (app "AOD", mapeável a um botão físico): ao abrir, alterna o AOD e mostra a imagem do novo
  estado com um interruptor "AOD". A tela fica aberta até o usuário sair; o interruptor e uma nova
  pressão do botão mapeado alternam de novo. Apagar a tela pode fechá-la ou mantê-la; ao reacordar, ela
  mostra o estado atual sem alternar. Indisponível: imagem cinza, "AOD unavailable" e interruptor
  desabilitado.
- **Atualidade:** a complication é atualizada pelo sistema a cada 5 min enquanto está num mostrador
  ativo; uma mudança feita em Configurações aparece em até ~5 min com a tela ligada (medido: 2 min 25 s).
  Toque, gatilho e interruptor atualizam na hora (< 1 s).
- **Energia:** nenhum serviço, alarme ou job próprio; medido 8 acionamentos/h e 0,66 s de CPU/h com a
  complication no mostrador, e 0 sem ela. Ao adicionar a complication, a OnePlus mostra um aviso
  genérico de bateria (também para o Maps).
- **Falhas** geram uma linha `Log.w` na tag `AodToggle`; o caminho feliz não registra nada.
- Verificado no relógio em dois mostradores (Gravity e "Chic").
- **Repositório:** público; `dev` aceita só PR com squash e `main` só PR com merge commit, ambos sem
  force-push nem exclusão (rulesets do repositório). PR para `main` só passa vindo da `dev` deste
  repositório: o workflow `PR origin check` (`pull_request_target`, roda a cópia do branch padrão, a `dev`) é check
  obrigatório no ruleset `main`.

## Propósito

Atalho de um toque para ligar e desligar o Always-On Display do OnePlus Watch 3, que só tem essa opção
no fundo de Configurações → Tela: uma complication que mostra o estado do AOD no mostrador e o alterna
ao toque, e um gatilho que o usuário mapeia a um botão físico. Ferramenta pessoal, sem publicação em loja.

## Stack

- App Kotlin nativo para Wear OS, com build via Gradle (wrapper `./gradlew`).
- Comandos de verificação: `.claude/skills/task-verify/SKILL.md` → "Commands by subproject".
- CI (`.github/workflows/ci.yml`, job `build-check`) em runner do GitHub (`ubuntu-latest`): JDK 17 e o L2
  do app (`ktlintCheck detekt lintDebug testDebugUnitTest test assembleRelease`, release sem assinatura) e o
  `verify-archived-gates` do kit, em toda PR para `dev` e `main`; também em push na `dev` (cada merge),
  que grava o cache do Gradle lido pelas PRs (sem o `verify-archived-gates`, que precisa da base da PR).

## Arquitetura

Um módulo Android (`app`), Kotlin, `minSdk`/`targetSdk` 34, `compileSdk` 36, Views simples, sem rede.

- **Núcleo** (`rs.prelude.aodtoggle.core`, Kotlin puro, testado com JUnit 4): o porto `AodSettings`
  (permissão, ler, escrever); `AodToggle` (`current()` deriva ligado/desligado/indisponível — sem permissão
  ou chave ausente; `toggle()` não escreve quando indisponível, senão escreve o oposto e devolve o
  estado relido, registrando escrita sem efeito); `presentationOf` (cor e rótulo por estado);
  `tapActionFor` (TOGGLE quando disponível, REFRESH quando indisponível); `triggerViewOf` (interruptor
  marcado/habilitado e texto visível por estado).
- **Sistema** (`system`): `SystemAodSettings` implementa o porto sobre `Settings.Global` (`AOD_KEY` é o
  único lugar da chave) e liga o núcleo ao logcat; `AodImage` rasteriza o vector `aod_text` tingido
  na cor do estado num bitmap transparente.
- **Complication** (`complication`): `AodComplicationService` (`SuspendingComplicationDataSourceService`,
  `UPDATE_PERIOD_SECONDS = 300`) entrega `SmallImageComplicationData` com um `PendingIntent` explícito e
  imutável cuja ação vem do estado exibido; `ComplicationTapReceiver` (não exportado) alterna só em
  TOGGLE e sempre pede o redesenho (`requestUpdateAll`).
- **Gatilho** (`trigger`): `TriggerActivity` de lançador (`singleTop`, `noHistory`), que alterna em
  `onCreate` e `onNewIntent`, alterna no clique do interruptor, relê sem alternar em `onRestart` e na
  recriação, e pede o redesenho da complication a cada alternância.
- **Build:** Gradle com version catalog; ktlint, detekt e Android lint; release assinado com propriedades
  `aodtoggle.keystore.*` lidas de `~/.gradle/gradle.properties`; debug com sufixo `.debug`. Um teste
  instrumentado (`connectedDebugAndroidTest`) prova no relógio que o app lê e escreve a chave.
