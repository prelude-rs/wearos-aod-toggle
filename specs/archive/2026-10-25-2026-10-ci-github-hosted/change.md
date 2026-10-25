---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: Done               <!-- In Progress → Done (ao arquivar) -->
Verdict: COMPLETE
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: o CI do kit roda em runner self-hosted, que a prelude-rs não tem; passa a rodar em runner do GitHub (ubuntu-latest) e ganha o L2 do Gradle, sem mudança no app
---
# 2026-10-ci-github-hosted
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->

- `.github/workflows/ci.yml`, job `build-check`: `runs-on: self-hosted` → `ubuntu-latest`; novos passos
  `actions/setup-java@v4` (Temurin 17), `gradle/actions/setup-gradle@v4` e o L2 do app
  (`./gradlew --no-daemon ktlintCheck detekt lintDebug testDebugUnitTest test assembleRelease`, release sem
  assinatura). Os passos do kit continuam; os que dependem de `tests/` se pulam sozinhos neste repositório.
- `specs/SOURCE-OF-TRUTH.md` § Stack descreve o CI.
- Fora do repositório (depois do merge, pelo agente com o `gh`, a pedido do autor): `build-check` como check
  obrigatório nos rulesets `dev` e `main`.
## Por quê        <!-- preenchido no PR -->

O `ci.yml` do kit assume runner self-hosted (o da ForSellers); a prelude-rs não tem nenhum (conferido:
0 runners na organização e no repositório), então o CI ficava na fila para sempre e não verificava nada.
Repositório público tem minutos de Actions sem custo no runner do GitHub.
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

- CI do PR #3 (run 40230905493, `ubuntu-latest`): `build-check` verde em 2 min 33 s; passo do L2:
  `BUILD SUCCESSFUL in 2m 22s`, 86 tarefas executadas; `verify-archived-gates` contra `origin/dev` rodou.
- Local: o app não mudou; L2 local verde na change anterior (`2026-10-pr-origin-guard`).

## Seções do SoT afetadas

<!-- Uma linha por seção do `specs/SOURCE-OF-TRUTH.md` que esta change altera, com os requisitos —
     aferida nos dois sentidos no arquivamento (seção declarada sem toque reprova; seção tocada sem
     declaração reprova). Sem delta no SoT: escreva `SOT-NO-DELTA: <motivo>`. Fonte da regra:
     spec-layout → regra 5(b). -->

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Stack | CI em runner do GitHub com o L2 do Gradle |
