# Adoption decisions

| timestamp | phase | item | decision / value | approved-by |
|---|---|---|---|---|
| 2026-10-24T22:04:04-03:00 | ASSESS | stage | greenfield (diretório vazio, sem git) | ricardo |
| 2026-10-24T22:04:04-03:00 | ASSESS | git | `git init` antes do conform | ricardo |
| 2026-10-24T22:04:04-03:00 | ASSESS | stack | Kotlin nativo Wear OS (Gradle) | ricardo |
| 2026-10-24T22:04:04-03:00 | CONFORM | CLAUDE.md name | `# wearos-complication-aod-toggle` | ricardo |
| 2026-10-24T22:04:04-03:00 | CONFORM | task-verify commands | JDK 17 + Android SDK; L1 ktlintCheck detekt lintDebug + testDebugUnitTest; L2 assembleRelease + test; L3 connectedDebugAndroidTest; artifact smoke adb install | ricardo |
| 2026-10-24T22:04:04-03:00 | CONFORM | Tier-3 | `*.kt\|*.kts\|*.java\|*/AndroidManifest.xml` | ricardo |
| 2026-10-24T22:04:04-03:00 | CONFORM | SOURCE-OF-TRUTH seed | esqueleto mínimo "sistema ainda não existe" (proposto pelo agente; revisão humana pendente) | ricardo (modo) |
| 2026-10-24T22:05:25-03:00 | CONFORM | SOURCE-OF-TRUTH seed | esqueleto mínimo aceito; propósito confirmado | ricardo |
| 2026-10-24T22:05:25-03:00 | VALIDATE | 1st validate | exit 1 só por hook-refs (settings.json inexistente antes do activate, inconsistência do kit 0.9.0); decisão: seguir para activate + verify final | ricardo |
| 2026-10-24T22:05:31-03:00 | VALIDATE | activate + final verify | settings.json aplicado; verify final 8/8 PASS (exit 0) | ricardo |
