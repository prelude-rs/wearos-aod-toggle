---
Mode: fast                 <!-- token de protocolo; require-approved-spec e verify-archived-gates leem -->
Status: Done               <!-- In Progress → Done (ao arquivar) -->
Verdict: COMPLETE
<!-- Verdict: PENDING → COMPLETE (no PR); verify-archived-gates lê o VALOR do 1º `^Verdict:`
     (comentário removido). Mantenha o comentário FORA da linha do valor. -->
Justification: change de release 0.2.0 — fecha o [Unreleased] do CHANGELOG (seq 5, 6, 7) e ajusta versionName/versionCode do app; sem decisão de design
---
# 2026-10-release-0.2.0
<!-- authorized-by: Ricardo Nogueira on 2026-10-25 -->

## O que mudou    <!-- preenchido no PR -->

- `CHANGELOG.md`: `## [Unreleased]` fechado como `## [0.2.0] - 2026-10-25` (seq 5, 6 e 7), novo
  `## [Unreleased]` vazio acima; `**Changes de release (sem item):** seq 4, 8`.
- `app/build.gradle.kts`: `versionName` "0.1.0" → "0.2.0"; `versionCode` 1 → 2 (o sideload da release
  nova é uma atualização e mantém a permissão concedida).
## Por quê        <!-- preenchido no PR -->

Fecha a versão com as duas changes de complication (imagem monocromática, seq 6; texto curto, seq 7) e o
cache da CI (seq 5), na mesma PR, a pedido do autor. A promoção `dev` → `main` sai do merge commit desta
PR; a tag `v0.2.0` e a publicação são do autor (`spec-layout` → "Changelog de release").
## Verificação    <!-- task-verify L2 (lint/test/build): colar comandos + resultado -->

- `JAVA_HOME=…/17.0.18-tem ./gradlew --no-daemon ktlintCheck detekt lintDebug test assembleRelease`
  → BUILD SUCCESSFUL; `aapt dump badging app-release.apk` → `versionCode='2' versionName='0.2.0'`.
- `verify-archived-gates` (inclui `check-release-changelog`) contra `origin/dev`: ver o commit de archive.

## Seções do SoT afetadas

SOT-NO-DELTA: o SoT não registra versão; o release só fecha o changelog e muda versionName/versionCode.
