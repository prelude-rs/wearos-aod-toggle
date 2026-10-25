---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: Done               <!-- In Progress → Done (ao arquivar) -->
Verdict: COMPLETE
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: change de release 0.1.0 — fecha o [Unreleased] do CHANGELOG e ajusta o versionName do app; sem decisão de design
---
# 2026-10-release-0.1.0
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->

- `CHANGELOG.md`: `## [Unreleased]` fechado como `## [0.1.0] - 2026-10-25` (seq 1, 2 e 3), novo
  `## [Unreleased]` vazio acima; `**Changes de release (sem item):** seq 4`.
- `app/build.gradle.kts`: `versionName` "1.0" → "0.1.0" (`versionCode` continua 1).
## Por quê        <!-- preenchido no PR -->

Primeiro release do projeto, escolhido pelo autor como 0.1.0. A promoção `dev` → `main` sai do merge
commit desta change; a tag `v0.1.0` e a publicação são do autor (`spec-layout` → "Changelog de release").
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

- `JAVA_HOME=…/17.0.18-tem ./gradlew clean ktlintCheck detekt lintDebug testDebugUnitTest test assembleRelease`
  → BUILD SUCCESSFUL; `aapt dump badging` → `versionName='0.1.0'`, `versionCode='1'`.
- `verify-archived-gates` (inclui `check-release-changelog`) contra `origin/dev`: PASS.

## Seções do SoT afetadas

SOT-NO-DELTA: o SoT não registra versão; o release só fecha o changelog e muda o `versionName`.
