# Consistency Report — 2026-10-aod-toggle-complication

Verdict: FAIL
**Justificativa de tamanho:** rodada 5 sobre o delta desde `798d042` (reabertura do Gate 1): 1 BLOCKING e 6 WARNING, cada um com sítio e conserto.

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 2        | 5       | 0           | —    |
| 2 | PASS    | 0        | 5       | 0           | 337545f |
| 3 | FAIL    | 1        | 5       | 0           | 0e7bf17 |
| 4 | PASS    | 0        | 4       | 0           | 21200cd |
| 5 | FAIL    | 1        | 6       | 0           | 798d042 |

- Parada após a rodada 5: Ricardo Nogueira, 2026-10-25 — continuar com teto (consertar B1 e avisos no design) — teto +1

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:41, design.md:208 (keystore própria) | Aberto desde a rodada 4 e fora do delta: a keystore própria continua sem R* que a motive; o design a declara preferência do autor. | Já reconhecido na Gate 1.5; reconhecer de novo na reaprovação do design. |
| W2 | WARNING | design.md:105-109, design.md:203, design.md:329-334 (Task 11, ícone de lançador) | O ícone novo (fundo transparente, aro `#3A3A3A`, arte N1 em escala 0,62) não tem R* que o motive. A Task 11 cita só R1, e R1 trata da imagem da complication. O ícone aparece apenas na narrativa "Reabertura do Gate 1" (spec.md:338), fora da tabela de requisitos. A revisão visual da Task 11 vai julgar o ícone sem critério de aceite. | Reconhecer o ícone como escopo do autor na Gate 1.5. Se ele for requisito, a spec ganha um R* com critério de aceite numa nova reabertura do Gate 1. |

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| B1 | BLOCKING | design.md:354 (Task 14, passo da lista) × docs/manual-checklist.md:53 (F1), :54 (F2), :71 (T3), :72 (T4) | A Task 14 só manda acrescentar itens, retirar N8/T5 e atualizar a tabela de cobertura. Os itens que já existem continuam afirmando o comportamento revogado. F2 espera para N7 "Sem meta de atualidade" e é o item que a cobertura liga a N7. T3 espera que o gatilho "volta ao mostrador" sozinho. T4 espera "por ~1 s e fecha". F1 espera "AOD" na lista do seletor, quando R12 pede "AOD Toggle". Executada assim, a lista de R10 verifica R7, R8, N7 e R12 contra critérios que a spec reaprovada contradiz. | No passo da lista da Task 14, mandar reescrever o "Esperado" de F1 (nome "AOD Toggle"), F2 (N7 ≤ ~5 min com a tela ligada, ou o item N7 novo no lugar de F2 na cobertura), T3 (tela com interruptor que fica aberta) e T4 (interruptor desabilitado, tela aberta, sem fechar). |
| W3 | WARNING | design.md:105, design.md:203 ("variação R3", "Escolha do autor (R3)"), design.md:329 ("ícone R3") | "R3" é também o ID do requisito "sem permissão → indisponível" (spec.md R3). Na linha do Decisions log, "(R3)" se lê como o requisito que motiva a decisão. Quem rastreia IDs (gate, revisão, `validation-gate`) liga o ícone a R3 por engano. | Renomear a prévia escolhida para um nome que não seja ID de requisito (por exemplo, "prévia de ícone 3") nas três ocorrências. |
| W4 | WARNING | design.md:111-113 (arte N1) × spec.md R1 ("anel … com 1,25× a altura das letras") | As letras ocupam y 35–65, ou seja, 30 de altura. O anel tem raio de traço 17,2 e `strokeWidth` 3,6, o que dá diâmetro externo 2 × (17,2 + 1,8) = 38. Isso é 1,267× a altura das letras, e não 1,25× (37,5), como o design afirma. Os números e a frase não fecham. | Ou ajustar o raio do traço para 16,95 (diâmetro externo 37,5), ou escrever "≈1,27× (medido na prévia N1)" e deixar a revisão visual da Task 11 decidir. |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`).

## Check 5 — Unstated assumptions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W5 | WARNING | design.md:94 (`TriggerActivity`: `noHistory`, "Não se fecha sozinha: sai com o botão ou deslizando") × spec.md R7/R8 ("a tela fica aberta até o usuário sair (botão ou deslizar)") | Com `noHistory`, a activity é finalizada em `onStop`. Quando a tela apaga (pulso abaixado, tempo de tela) ou o Wear volta ao mostrador por inatividade, o gatilho some sem o usuário ter saído. O design não diz se isso cumpre R7/R8. A lista manual pode registrar isso como falha de R7. | Em design.md:94, dizer que apagar a tela ou a volta automática ao mostrador encerra a tela (`noHistory`) e perguntar ao autor se isso conta como "sair". Se não contar, trocar o mecanismo. Registrar a resposta como item da Task 14. |

## Check 6 — Verifiability
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W6 | WARNING | design.md:175 (N7, "tela ligada, cronometrar … ≤ ~5 min") e design.md:354 (Task 14, item N7) | A tela do relógio apaga em segundos. Manter a tela ligada até 5 min exige um meio que nem o design nem a Task 14 nomeiam. Sem esse meio, a medida cai no caso "tela apagada, sem meta" de N7 e não verifica nada. O mesmo vale para N6: `batterystats` não acumula com o relógio no carregador, e o README avisa que o adb por Wi-Fi cai com a tela apagada. | Na Task 14, nomear o meio de manter a tela ligada no item N7 (por exemplo, `adb shell svc power stayon true` ou "Permanecer ativo" nas opções de desenvolvedor, desfeito na restauração final). No item N6, dizer que a hora de medida roda fora do carregador e que se reconecta o adb antes de ler `dumpsys batterystats`. |

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
n.a. — 14 blocos em `## Decomposição` (≤16); a justificativa de dimensionamento lê `N/A`.

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
sem achados

## Minimal edit set (on FAIL)
### Edições no design
- design.md:354 (Task 14) — reescrever o "Esperado" de F1, F2, T3 e T4 de `docs/manual-checklist.md` para R7, R8, N7 e R12 reaprovados (B1).

### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
