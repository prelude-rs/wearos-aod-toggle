---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: In Progress        <!-- In Progress → Done (ao arquivar) -->
Verdict: PENDING
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: o CI passa a rodar também em push na dev (para gravar o cache do Gradle que as PRs leem), tira o teste de unidade duplicado e corrige o texto que descreve onde o guard de origem roda; sem mudança no app
---
# 2026-10-ci-gradle-cache
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
| Estado atual | onde o guard de origem roda (workflow do branch padrão, `dev`) |
| Stack | CI também em push na `dev`, com cache do Gradle |
