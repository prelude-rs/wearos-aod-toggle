# Consistency Report — 2026-10-aod-toggle-complication

Verdict: PASS
**Justificativa de tamanho:** rodada 2 sobre o delta desde `337545f`, 5 WARNING com sítio e conserto cada.

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 2        | 5       | 0           | —    |
| 2 | PASS    | 0        | 5       | 0           | 337545f |

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:37, design.md:175, design.md:221 (keystore própria) | A nova justificativa (design.md:175) motiva um APK de release **assinado**: o "Artifact smoke" do `task-verify` (task-verify/SKILL.md:72) faz `adb install -r` do release, e o Android recusa instalar APK sem assinatura. Não motiva a **keystore própria**: a alternativa rejeitada na mesma linha, a chave de debug, também passa no smoke. A keystore própria continua sem R* que a motive, sustentada só por "pedido do autor". | O humano reconhece a keystore própria como escopo aceito na Gate 1.5, ou o release passa a ser assinado com a chave de debug e a keystore própria sai do design. |

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W2 | WARNING | design.md:175 × design.md:37/design.md:221 ("ausente → sem assinatura") × design.md:112 (`installDebug`) × task-verify/SKILL.md:72 | O design diz que o Artifact smoke exige assinatura, mas cria dois caminhos em que esse smoke falha. (1) Sem as propriedades `aodtoggle.keystore.*` o release sai sem assinatura e `adb install` rejeita o APK (`INSTALL_PARSE_FAILED_NO_CERTIFICATES`). (2) Debug e release usam o mesmo `applicationId` (design.md:189) com chaves diferentes. Depois do `installDebug` do Dev-run e da Task 3, o `adb install -r` do release falha com `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Desinstalar antes resolve, mas perde o `pm grant` (design.md:162-163). | Em design.md:221 e no Rollout, escolher e escrever uma de três saídas: (a) sem as propriedades, o release cai para a assinatura de debug, e o smoke desinstala o debug antes e refaz o `pm grant`; (b) `applicationIdSuffix` no debug, para os dois builds conviverem; (c) aceitar o smoke como `DEFERRED` sem as propriedades, como prevê task-verify/SKILL.md:89. |
| W3 | WARNING | design.md:233 (Task 3: "`read()` nulo em `SettingNotFoundException`") e design.md:54 (`// null = chave ausente`) × design.md:75 | Pelo fechamento do B2 da rodada 1, `read()` também captura `SecurityException`, mas só a tabela de interfaces (design.md:75) recebeu a mudança. O passo da Task 3, que é o que o executor subagent-driven segue, ainda lista só `SettingNotFoundException`. Uma `SecurityException` não capturada derruba o serviço, o receiver e o gatilho. | Em design.md:233, ler "`read()` nulo em `SettingNotFoundException` e em `SecurityException`, com linhas de log distintas". Em design.md:54, ler `// null = chave ausente ou leitura negada`. |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`).

## Check 5 — Unstated assumptions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W4 | WARNING | design.md:180-185 (Assumptions 1 e 2) | As duas premissas agora estão escritas, mas só no design. A premissa 1 estende à leitura o risco da spec ("A concessão `pm grant` …"), que a spec escreve com efeito só em R4/R7. Uma leitura negada derruba também R1–R3. A premissa 2 (redesenho em ≤ 1 s) não tem risco nem mitigação na spec, e o "a decisão é do autor" de design.md:185 deixa a pergunta sem resposta. | Na Gate 1.5, o humano responde às duas premissas: aceita-as como estão, ou dita o que acontece se N1 falhar por causa do mostrador. Se quiser as premissas na spec, a edição passa por nova transcrição do Gate 1. |

## Check 6 — Verifiability
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W5 | WARNING | design.md:235 (Task 3, passo "No relógio, antes das demais tasks") | Na Task 3 o app não tem nenhum componente que chame `SystemAodSettings`: o serviço vem na Task 5, o receiver na 6 e o gatilho na 7. O design também não tem `androidTest` (design.md:36). O passo manda "confirmar que o app lê … escreve … e que `checkSelfPermission` reporta", mas nada no app executa esse código, e não há onde ver o resultado. O passo não roda como está escrito. O executor vai pular ou improvisar justo a mitigação antecipada do risco que reabre a spec. | Dizer no passo por onde o app é exercitado. (a) Um teste instrumentado em `app/src/androidTest`, rodado por `./gradlew connectedDebugAndroidTest` (já é o comando L3 do `task-verify`), com a concessão feita antes da execução. (b) Ou mover o passo para o fim da Task 7: `adb shell am start` do gatilho mais `adb shell settings get global ambient_enabled`, antes, depois e com `pm revoke`. |

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
n.a. — 9 blocos em `## Decomposição` (≤16); a justificativa de dimensionamento lê `N/A`.

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
sem achados

## Minimal edit set (on FAIL)
### Edições no design
- design.md:221 e design.md:161-163 → saída escolhida para o smoke de release: fallback para a chave de debug, `applicationIdSuffix` no debug ou `DEFERRED` (W2).
- design.md:233 → `read()` nulo também em `SecurityException`, com log distinto (W3).
- design.md:54 → comentário `// null = chave ausente ou leitura negada` (W3).
- design.md:235 → nomear o meio de exercitar o app no relógio: `androidTest` com `connectedDebugAndroidTest`, ou o passo movido para o fim da Task 7 (W5).
- design.md:37, design.md:175 → manter a keystore própria com reconhecimento na Gate 1.5, ou trocar pela chave de debug (W1).
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
