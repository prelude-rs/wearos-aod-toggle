# Consistency Report — 2026-10-aod-toggle-complication

Verdict: FAIL
**Justificativa de tamanho:** rodada 3 sobre o delta desde `0e7bf17`: 1 BLOCKING e 5 WARNING, cada um com sítio e conserto.

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 2        | 5       | 0           | —    |
| 2 | PASS    | 0        | 5       | 0           | 337545f |
| 3 | FAIL    | 1        | 5       | 0           | 0e7bf17 |

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:37, design.md:178 (keystore própria) | A keystore própria continua sem R* que a motive. Agora o design diz isso corretamente: "preferência do autor, não exigência". O humano já aceitou isso como escopo. Mas a linha 178 escreve "escopo aceito no Gate 1.5" antes de a Gate 1.5 acontecer, e com isso registra como fato uma aprovação que ainda não houve. | Reconhecer na Gate 1.5. Até lá, ler em design.md:178 "escopo a reconhecer no Gate 1.5". |

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| B1 | BLOCKING | design.md:191-195 (premissa 2) × spec.md:58 (N1) | N1 tem um alvo só, de ponta a ponta: "≤ 1 s do toque … até o novo estado visível", medido por cronômetro ou gravação. Não há recorte para o tempo do mostrador. A premissa 2 agora diz que mais de 1 s num mostrador, quando vem do redesenho do mostrador, é "aceita, e não como falha do app". As duas frases não podem valer juntas. O design dispensa de antemão uma medida que a spec aprovada reprova, e o `validation-gate` julga contra a spec. | Opção (a), só no design: ler na premissa 2 "se passar de 1 s num mostrador, N1 falha nesse mostrador. O autor decide no `validation-gate` se dispensa a falha, e a dispensa fica registrada no `evidence.md` com nome e data". Isso mantém a decisão humana pelo canal de dispensa do `validation-gate`. Opção (b): se o humano quiser o recorte no contrato, reabrir o Gate 1 para N1, com nova transcrição. |
| W4 | WARNING | design.md:37 e design.md:179 ("cada um com sua própria concessão", "sem perder a concessão de cada variante") × design.md:247 (`connectedDebugAndroidTest`) | Por padrão, a tarefa `connected…AndroidTest` do AGP desinstala o APK testado e o APK de teste ao fim da execução. A propriedade `android.injected.androidTest.leaveApksInstalledAfterRun` existe justamente para evitar isso. A Task 3 e todo L3 removem o `cc.floresta.aodtoggle.debug` junto com o seu `pm grant`. A promessa de não perder a concessão do debug é falsa. Depois da Task 3, o Dev-run mostra cinza até alguém reinstalar e conceder de novo. | Em design.md:37 e design.md:179, dizer que a concessão do debug se perde a cada `connectedDebugAndroidTest` e que o Dev-run refaz `installDebug` e `pm grant`. Outra saída: fixar `leaveApksInstalledAfterRun` e dizer onde. |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`).

## Check 5 — Unstated assumptions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W3 | WARNING | design.md:246-247 (Task 3, teste instrumentado com `pm revoke` do próprio pacote) e design.md:101 | O teste instrumentado roda dentro do processo do app testado. No Android, revogar uma permissão runtime mata os processos do uid do app. O design não diz se a revogação de `WRITE_SECURE_SETTINGS`, uma permissão de desenvolvimento, faz o mesmo no Wear OS 5 (API 34). A premissa fica sem registro. Se o processo morrer, a execução da instrumentação acaba como queda do processo, e design.md:247 leria isso como "falha de leitura ou escrita pelo app", reabrindo a spec por um defeito do arnês, não da premissa 1. | Escrever a premissa e separar os casos. O caso revogado vai num método próprio, executado por último. Ou sai do teste instrumentado e fica com a lista manual, que já reproduz o estado indisponível com `pm revoke` (design.md:120). Em design.md:247, ler que só uma falha de asserção na leitura ou na escrita, com a concessão feita, reabre a spec. |
| W5 | WARNING | design.md:37 e design.md:199 (debug e release coexistem) × design.md:278 (Task 8, README) e design.md:283-284 (Task 9, lista manual) | Com `applicationIdSuffix ".debug"`, o relógio pode ter dois apps com o mesmo rótulo e o mesmo ícone, dois provedores "AOD" no seletor de complication e duas entradas no mapeamento de botão. O README (R11, "o roteiro usado em R10") e a lista manual não dizem qual variante se instala, qual pacote recebe o `pm grant`, nem qual entrada se escolhe. Se o revisor escolher a variante sem concessão, R3 e R8 aparecem onde se esperava R4 e R7. N4 inspeciona o release enquanto o Dev-run exercita o debug. | Nas Tasks 8 e 9, nomear a variante da lista manual (o release, pelo README) e o pacote do `pm grant`. Dar ao debug um rótulo distinto (por exemplo, `app_name` por variante) ou mandar desinstalar o debug antes da lista. |

## Check 6 — Verifiability
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W2 | WARNING | design.md:194-195 ("Se o atraso estiver no app … é falha de N1") e design.md:218 ("a medida separa o tempo do app do tempo do mostrador") × spec.md:62 (N5) | Nenhum instrumento separa os dois tempos. O cronômetro ou a gravação de N1 não enxerga o instante de `requestUpdateAll()`. O instrumento óbvio, uma linha de logcat com hora no caminho feliz, viola N5 ("o caminho feliz não registra nada"). Sem a separação, nenhum revisor aplica o critério de design.md:194-195, e todo atraso pode ser atribuído ao mostrador. | Nomear um instrumento que não exija log no caminho feliz e dizer em que item da Task 9 ele entra. Por exemplo: um trace do Perfetto que capture a execução do `ToggleReceiver`, ou o gatilho como referência do tempo do app, já que ele mostra o estado assim que `toggle()` retorna. Ou retirar a separação e julgar N1 de ponta a ponta, conforme o conserto de B1. |

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
- design.md:191-195 → premissa 2: mais de 1 s num mostrador é falha de N1 nesse mostrador, e a dispensa é do autor no `validation-gate`, registrada no `evidence.md`. Remover "aceita, e não como falha do app" (B1).
- design.md:194-195, design.md:218 → nomear o instrumento que separa o tempo do app do tempo do mostrador sem log no caminho feliz, ou retirar a separação (W2).
- design.md:246-247 → registrar a premissa sobre a revogação no processo da instrumentação. Isolar ou mover o caso revogado. Só falha de asserção, com a concessão feita, reabre a spec (W3).
- design.md:37, design.md:179 → a concessão do debug se perde a cada `connectedDebugAndroidTest`, e o Dev-run reinstala e concede de novo. Ou fixar `leaveApksInstalledAfterRun` (W4).
- design.md:278, design.md:283-284 → variante e pacote da lista manual e do README. Rótulo distinto para o debug, ou desinstalação antes da lista (W5).
- design.md:178 → "escopo a reconhecer no Gate 1.5" (W1).
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
