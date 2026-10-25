---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: Done               <!-- In Progress → Done (ao arquivar) -->
Verdict: COMPLETE
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: um workflow que exige que PRs para `main` venham da `dev` (cópia adaptada do guard da ForSellers) e a correção do título do SoT; sem decisão de design além de `pull_request_target` em vez de `pull_request`
---
# 2026-10-pr-origin-guard
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->

- `.github/workflows/pr-origin-check.yml` (novo): job `pr-origin-check`, em `pull_request_target` para a
  `main` (tipos `opened`, `synchronize`, `reopened`, `edited`), reprova a PR cuja origem não é a `dev` deste
  repositório (branch `dev` de um fork também reprova). Sem checkout, sem permissões, campos do evento só
  por variável de ambiente.
- `specs/SOURCE-OF-TRUTH.md`: título com o nome atual (`wearos-aod-toggle`) e as regras de branch em
  "Estado atual".
- Fora do repositório (configuração do GitHub, feita pelo agente com o `gh`, a pedido do autor): rulesets
  `dev` (só squash) e `main` (só merge commit), repositório público. O check `pr-origin-check` entra como
  obrigatório no ruleset `main` depois que este arquivo chegar à `main` (antes disso o
  `pull_request_target` não tem o que rodar na base).
## Por quê        <!-- preenchido no PR -->

O autor quer na prelude-rs a regra da ForSellers "PR para `main` só a partir da `dev`". Lá ela é imposta
pelo ruleset da organização (regra `workflows`), que o plano Free da prelude-rs não tem; o guard passa a
viver no repositório, protegido de edição pela PR por `pull_request_target`. O título do SoT ficou com o
nome antigo na change anterior (ruling R21 de `2026-10-aod-toggle-complication`).
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

- `JAVA_HOME=…/17.0.18-tem ./gradlew clean ktlintCheck detekt lintDebug testDebugUnitTest test assembleRelease`
  → BUILD SUCCESSFUL (o app não mudou).
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/pr-origin-check.yml'))"` → YAML válido
  (`actionlint` não instalado).
- O comportamento do guard é verificado no GitHub: a PR de release `dev`→`main` deste mesmo trabalho deve
  passar; uma PR de teste de outra branch para a `main` deve reprovar (registrado na PR).

## Seções do SoT afetadas

<!-- Uma linha por seção do `specs/SOURCE-OF-TRUTH.md` que esta change altera, com os requisitos —
     aferida nos dois sentidos no arquivamento (seção declarada sem toque reprova; seção tocada sem
     declaração reprova). Sem delta no SoT: escreva `SOT-NO-DELTA: <motivo>`. Fonte da regra:
     spec-layout → regra 5(b). -->

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| SOURCE-OF-TRUTH — wearos-aod-toggle | título com o nome atual do projeto |
| Estado atual | regras de branch do repositório (dev só squash; main só merge commit e só a partir da dev) |
