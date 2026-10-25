---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: In Progress        <!-- In Progress → Done (ao arquivar) -->
Verdict: PENDING
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: o CI do kit roda em runner self-hosted, que a prelude-rs não tem; passa a rodar em runner do GitHub (ubuntu-latest) e ganha o L2 do Gradle, sem mudança no app
---
# 2026-10-ci-github-hosted
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->
## Por quê        <!-- preenchido no PR -->
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

## Seções do SoT afetadas

<!-- Uma linha por seção do `specs/SOURCE-OF-TRUTH.md` que esta change altera, com os requisitos —
     aferida nos dois sentidos no arquivamento (seção declarada sem toque reprova; seção tocada sem
     declaração reprova). Sem delta no SoT: escreva `SOT-NO-DELTA: <motivo>`. Fonte da regra:
     spec-layout → regra 5(b). -->

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Stack | CI em runner do GitHub com o L2 do Gradle |
