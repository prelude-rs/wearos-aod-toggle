---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: In Progress        <!-- In Progress → Done (ao arquivar) -->
Verdict: PENDING
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: a tela do gatilho fecha sozinha 3 s depois de mostrar o estado (contagem recomeça a cada alternância); tempo escolhido pelo autor, sem decisão de design
---
# 2026-10-trigger-auto-close

## O que mudou    <!-- preenchido no PR -->
## Por quê        <!-- preenchido no PR -->
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

## Seções do SoT afetadas

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Estado atual | gatilho fecha sozinho em 3 s |
| Arquitetura | `TriggerActivity` agenda o fechamento |
