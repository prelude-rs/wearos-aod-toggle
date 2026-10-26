---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: Done               <!-- In Progress → Done (ao arquivar) -->
Verdict: COMPLETE
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: change de release 0.2.1 — fecha o [Unreleased] do CHANGELOG (seq 9) e ajusta versionName 0.2.1 / versionCode 3; sem decisão de design
---
# 2026-10-release-0.2.1
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->

- `CHANGELOG.md`: `## [Unreleased]` fechado como `## [0.2.1] - 2026-10-25` (seq 9), novo `## [Unreleased]`
  vazio acima; `**Changes de release (sem item):** seq 4, 8, 10`.
- `app/build.gradle.kts`: `versionName` "0.2.0" → "0.2.1"; `versionCode` 2 → 3.
## Por quê        <!-- preenchido no PR -->

Fecha a versão com o fechamento automático do gatilho (seq 9), na mesma PR, a pedido do autor, que vai
verificar a mudança com esta release instalada (sem build de debug). Promoção, tag `v0.2.1` e publicação
são do autor.
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

- `JAVA_HOME=…/17.0.18-tem ./gradlew --no-daemon ktlintCheck detekt lintDebug test assembleRelease`
  → BUILD SUCCESSFUL; `aapt dump badging app-release.apk` → `versionCode='3' versionName='0.2.1'`.
- `verify-archived-gates` (inclui `check-release-changelog`) contra `origin/dev`: PASS.

## Seções do SoT afetadas

SOT-NO-DELTA: o SoT não registra versão; o release só fecha o changelog e muda versionName/versionCode.
