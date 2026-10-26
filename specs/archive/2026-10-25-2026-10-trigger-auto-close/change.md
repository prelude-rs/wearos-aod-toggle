---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: Done               <!-- In Progress → Done (ao arquivar) -->
Verdict: COMPLETE
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: a tela do gatilho fecha sozinha 3 s depois de mostrar o estado (contagem recomeça a cada alternância); tempo escolhido pelo autor, sem decisão de design
---
# 2026-10-trigger-auto-close
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->

- `trigger/TriggerActivity.kt`: cada render agenda `finish()` para `AUTO_CLOSE_MS` = 3 s depois, num
  `Handler` do looper principal, cancelando o agendamento anterior; `onDestroy` cancela o pendente. Como o
  render acontece a cada alternância (abertura, nova pressão do botão, interruptor) e ao reacordar, a
  contagem recomeça a cada uma. KDoc atualizado.
- `docs/manual-checklist.md`: T3 e T4 esperam o fechamento em 3 s.
- `specs/SOURCE-OF-TRUTH.md`: Estado atual e Arquitetura descrevem o fechamento.
## Por quê        <!-- preenchido no PR -->

A tela do gatilho só fechava quando o sistema apagava a tela e voltava ao mostrador, o que demorava. O
autor quer ver o novo estado e voltar sozinho ao mostrador em 3 s.
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

- `JAVA_HOME=…/17.0.18-tem ./gradlew --no-daemon ktlintCheck detekt lintDebug test assembleRelease`
  → BUILD SUCCESSFUL (ver o commit de archive).
- No relógio: verificado com a release 0.2.1 instalada após a tag (decisão do autor: sem build de
  debug nesta change); resultado registrado na PR.

## Seções do SoT afetadas

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Estado atual | gatilho fecha sozinho em 3 s |
| Arquitetura | `TriggerActivity` agenda o fechamento |
