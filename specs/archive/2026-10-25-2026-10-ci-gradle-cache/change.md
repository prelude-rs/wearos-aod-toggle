---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: Done               <!-- In Progress → Done (ao arquivar) -->
Verdict: COMPLETE
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: o CI passa a rodar também em push na dev (para gravar o cache do Gradle que as PRs leem), tira o teste de unidade duplicado e corrige o texto que descreve onde o guard de origem roda; sem mudança no app
---
# 2026-10-ci-gradle-cache
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->

- `.github/workflows/ci.yml`: gatilho `push` em `dev` além de `pull_request`; passo "Verify archived gates"
  com `if: github.event_name == 'pull_request'`; L2 sem `testDebugUnitTest` (o `test` já roda debug e
  release).
- `.github/workflows/pr-origin-check.yml`: comentário corrigido — o `pull_request_target` roda a cópia do
  branch padrão (`dev`).
- `specs/SOURCE-OF-TRUTH.md`: "Estado atual" (onde o guard roda) e "Stack" (CI em push na `dev`, cache).
## Por quê        <!-- preenchido no PR -->

O CI levava ~2 min, quase todo no L2, e começava do zero em toda PR: o `setup-gradle` só grava o cache no
branch padrão, e o CI só rodava em `pull_request`, cujo cache o GitHub isola por PR. Repositório público:
as execuções a mais em push na `dev` não consomem minutos. O texto do guard dizia "cópia da `main`", mas
o GitHub usa o workflow do branch padrão (observado: o guard rodou na PR #5 antes de existir na `main`).
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

- CI da PR #6: `build-check` verde (`pull_request`, ainda sem cache). O ganho do cache se mede nas PRs
  seguintes ao merge (primeiro push na `dev` grava o cache).
- YAML validado (`yaml.safe_load`); o app não mudou.

## Seções do SoT afetadas

<!-- Uma linha por seção do `specs/SOURCE-OF-TRUTH.md` que esta change altera, com os requisitos —
     aferida nos dois sentidos no arquivamento (seção declarada sem toque reprova; seção tocada sem
     declaração reprova). Sem delta no SoT: escreva `SOT-NO-DELTA: <motivo>`. Fonte da regra:
     spec-layout → regra 5(b). -->

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Estado atual | onde o guard de origem roda (workflow do branch padrão, `dev`) |
| Stack | CI também em push na `dev`, com cache do Gradle |
