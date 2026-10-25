# Evidence: Complication e gatilho para alternar o AOD no OnePlus Watch 3

Change-ID: 2026-10-aod-toggle-complication
Status: Pending          <!-- Pending | Complete -->
Verdict: —
<!-- Verdict: COMPLETE | INCOMPLETE — the validation-gate writes this. MUST be the first
     `^Verdict:` line; hooks/CI read the VALUE (comment stripped). Never translate the token.
     Keep the comment OFF the value's line: on it, the token inside the comment defeats the read. -->
Cross-model review: —    <!-- model used + agreement summary, or "unavailable in this environment" -->

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
Preview: <command of the Dev-run premise used>

| Round | Item (human feedback) | Fix (commit) | L1 |
|-------|-----------------------|--------------|----|

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

## Out-of-scope respected
<!-- Confirm each out-of-scope item was not implemented. -->

## Regression standing
<!-- Commands run (test suite, lints, build) and exit status. -->

- 2026-10-25 — `./gradlew connectedDebugAndroidTest` no OnePlus Watch 3 (OPWE242, Android 14 / API 34): exit 0, `SystemAodSettingsTest` 1 teste, 0 falhas. Premissa 1 provada (o app concedido lê e escreve `ambient_enabled`); valor do AOD restaurado ao anterior (`0`). Fecha o BLOCKED de R3/R6.
- 2026-10-25 14:17 — Task 17 (pacote `rs.prelude.aodtoggle.debug`): `./gradlew connectedDebugAndroidTest` no OPWE242: exit 0, `SystemAodSettingsTest` 1 teste, 0 falhas — premissa 1 refeita no pacote novo. Observação de arnês: com o relógio conectado por `IP:porta` (`adb connect 192.168.1.122:33233`) o AGP marca a tarefa como falha mesmo com o teste passando (a instrumentação crua dá `INSTRUMENTATION_CODE: -1`, o XML 1/1 verde); com o nome mDNS (`adb connect "adb-…(2)._adb-tls-connect._tcp"`) a tarefa fica verde. Release `rs.prelude.aodtoggle` instalado (14:18:05), assinado `O=prelude-rs`, permissão concedida; `cc.floresta.aodtoggle` desinstalado.

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
