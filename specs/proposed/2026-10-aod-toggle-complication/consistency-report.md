# Consistency Report — 2026-10-aod-toggle-complication

Verdict: PASS
**Justificativa de tamanho:** rodada 4 sobre o delta desde `21200cd`: 0 BLOCKING e 4 WARNING, cada um com sítio e conserto.

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 2        | 5       | 0           | —    |
| 2 | PASS    | 0        | 5       | 0           | 337545f |
| 3 | FAIL    | 1        | 5       | 0           | 0e7bf17 |
| 4 | PASS    | 0        | 4       | 0           | 21200cd |

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:37, design.md:178 (keystore própria) | A keystore própria continua sem R* que a motive. O design a declara preferência do autor e a marca como escopo a reconhecer no Gate 1.5. | Reconhecer na Gate 1.5. |

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W2 | WARNING | design.md:231 (Task 1, passo) × design.md:228 (Task 1, **Files**) e design.md:272 (Task 7 cria `values/strings.xml`) | O passo da Task 1 manda fixar `android.injected.androidTest.leaveApksInstalledAfterRun=true` no `gradle.properties` do projeto e dar ao debug o rótulo "AOD (debug)". O **Files** da Task 1 não lista `gradle.properties` nem o arquivo do rótulo. O mecanismo do rótulo também não está dito (recurso em `src/debug/res`, `resValue` ou `manifestPlaceholders`), e o `strings.xml` só nasce na Task 7. Um executor que siga o **Files** deixa de fora o que fecha a W4 e a W5 da rodada 3. Se o serviço (Task 5) ou a activity (Task 7) ganharem `android:label` próprio, o rótulo do debug não chega ao editor do mostrador nem ao mapeamento de botão, ao contrário do que diz design.md:37. | Acrescentar ao **Files** da Task 1 `gradle.properties` e o arquivo do rótulo (por exemplo, `app/src/debug/res/values/strings.xml` sobrepondo `app_name`). Dizer em design.md:37 que serviço e activity herdam o rótulo da aplicação e não declaram `android:label` próprio. |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`).

## Check 5 — Unstated assumptions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W3 | WARNING | design.md:283-284 (Task 9) e design.md:278 (Task 8) × design.md:37 (release sem keystore sai sem assinatura) | A lista manual (R10) e o README (R11) agora rodam sobre o **release**. Pelo design.md:37, sem a keystore o release sai sem assinatura. O Android recusa instalar APK sem assinatura (`INSTALL_PARSE_FAILED_NO_CERTIFICATES`). O design prevê a falta da keystore só para o "Artifact smoke" (`DEFERRED`) e não diz que R10 e R11 ficam sem execução. A premissa de que a keystore existe na hora da lista está implícita. | Em design.md:37 ou no cabeçalho da Task 9, escrever que a lista e o roteiro do README exigem o release assinado. Sem a keystore, R10 e R11 não se executam: a lista não roda sobre o debug, e o caso fica registrado como bloqueio no `evidence.md`. |

## Check 6 — Verifiability
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W4 | WARNING | design.md:246-247 (Task 3, critério de parada) | Pelo novo critério, só uma "falha de asserção com a concessão feita (leitura ou escrita negada ao app)" reabre a spec, e o erro de arnês "(conexão, instalação)" não conta. Fica sem casa a falha de `hasWritePermission()` logo após o `pm grant`. `UiAutomation.executeShellCommand` devolve um `ParcelFileDescriptor` e não espera o comando terminar. Se o teste não ler a saída até o fim, a asserção pode correr antes do grant. Uma corrida do arnês vira então uma falha de asserção, que o critério manda ler como falha da premissa 1. Se o grant de fato não pegar no app, é o risco da spec (spec.md:89), mas o critério não o nomeia. | Em design.md:246, dizer que o teste lê a saída do `pm grant` até o fim e fecha o descritor antes de qualquer asserção. Em design.md:247, classificar `hasWritePermission()` falso depois do grant concluído como falha da premissa 1 (risco de spec.md:89), e a saída de erro do próprio `pm grant` como erro de arnês. |

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
n.a. — 9 blocos em `## Decomposição` (≤16); a justificativa de dimensionamento lê `N/A`.

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
sem achados

## Minimal edit set (on FAIL)
n.a. — Verdict PASS; os consertos dos WARNING estão nas tabelas acima.
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
