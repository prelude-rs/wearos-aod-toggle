# Consistency Report — 2026-10-aod-toggle-complication

Verdict: PASS
**Justificativa de tamanho:** rodada 8 sobre o delta desde `959c3bf`: 0 BLOCKING e 6 WARNING, cada um com sítio e conserto.

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 2        | 5       | 0           | —    |
| 2 | PASS    | 0        | 5       | 0           | 337545f |
| 3 | FAIL    | 1        | 5       | 0           | 0e7bf17 |
| 4 | PASS    | 0        | 4       | 0           | 21200cd |
| 5 | FAIL    | 1        | 6       | 0           | 798d042 |
| 6 | PASS    | 0        | 5       | 0           | 93dbb89 |
| 7 | PASS    | 0        | 6       | 0           | aa20a70 |
| 8 | PASS    | 0        | 6       | 0           | 959c3bf |

- Parada após a rodada 5: Ricardo Nogueira, 2026-10-25 — continuar com teto (consertar B1 e avisos no design) — teto +1
- Parada após a rodada 6: Ricardo Nogueira, 2026-10-25 — reabrir o Gate 1 para o aro na complication (R1) — teto +1
- Parada após a rodada 7: Ricardo Nogueira, 2026-10-25 — reabrir o Gate 1 para retirar o aro da complication (R1) — teto +1
- Parada após a rodada 8: Ricardo Nogueira, 2026-10-25 — mudar pacote, nome do projeto e assinatura para prelude-rs dentro desta change — teto +1

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:41, design.md:211 (keystore própria) | Aberto desde a rodada 4 e fora do delta (a rodada 8 não o tocou): a keystore própria continua sem R* que a motive; o design a declara preferência do autor. | Já reconhecido na Gate 1.5; reconhecer de novo na reaprovação do design. |
| W2 | WARNING | design.md:106-110, design.md:206, design.md:337 (Task 11, ícone de lançador) | Aberto desde a rodada 5 e fora do delta: o ícone (fundo transparente, aro `#3A3A3A`, arte N1 em escala 0,62) continua sem R* que o motive; a spec só o menciona de passagem em R1 e na história ("o ícone do app mantém o aro cinza"). A Task 11 cita só R1, que trata da imagem da complication, e a revisão visual julga o ícone sem critério de aceite. | Reconhecer o ícone como escopo do autor na Gate 1.5. Se ele for requisito, a spec ganha um R* com critério de aceite numa nova reabertura do Gate 1. |

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W3 | WARNING | design.md:113 (raio do traço 16,95) × design.md:115 ("Valores medidos na prévia escolhida.") | Aberto desde a rodada 6 e fora do delta (o delta só retirou o aro, citado logo abaixo): o raio foi trocado de 17,2 (o valor medido na prévia N1) por 16,95 para fechar 1,25×, mas a frase seguinte ainda afirma que todos os valores foram medidos na prévia, o que deixou de valer para o raio. | Em design.md:115, dizer que o raio foi ajustado de 17,2 (medido) para 16,95 para cumprir 1,25× de R1, e que a revisão visual da Task 16 confere a arte sem aro. |
| W4 | WARNING | design.md:238 (Global Constraints: "Tela do gatilho: não se fecha sozinha.") × design.md:94 e design.md:310 (`noHistory` finaliza a tela quando o relógio apaga a tela ou volta sozinho ao mostrador) | Fora do delta: o design faz a tela fechar sem ação do usuário e a restrição global continua dizendo que ela não se fecha sozinha. Quem implementa ou revisa a Task 13 pela restrição pode tratar o fechamento por `noHistory` como defeito e trocar o mecanismo. | Em design.md:238, escrever "não se fecha por tempo; apagar a tela ou a volta automática ao mostrador a finaliza (`noHistory`), o que conta como o usuário sair (R7)". |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`).

## Check 5 — Unstated assumptions
sem achados

## Check 6 — Verifiability
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W5 | WARNING | design.md:359 (Task 14, meio de manter a tela ligada na medida de N7) | Fora do delta: `adb shell svc power stayon true` e "Permanecer ativo" só mantêm a tela ligada com o relógio na energia. A lista roda por adb sobre Wi-Fi e a Task 14 não manda pôr o relógio no carregador durante N7; fora dele, a tela apaga e a medida cai no caso "tela apagada, sem meta" de N7. | No item N7 da Task 14, mandar fazer a medida com o relógio no carregador (com `stayon` ligado) e confirmar que o mostrador com a complication continua visível durante a carga; se não, nomear outro meio (tempo limite de tela no máximo, restaurado no fim). |
| W6 | WARNING | design.md:363-368 (Task 15, aro na complication) × spec.md R1 ("sem aro") × design.md:372-378 (Task 16) | O delta tornou R1 contraditório com a Task 15: ela segue em `## Decomposição` mandando desenhar o aro (escala 0,62, raio 47), e a Task 16 a desfaz. Quem executa o plano de cima para baixo constrói o que R1 proíbe e depois o remove; um revisor lendo só a Task 15 vê a violação de R1. A Task 16 cobre o F1 do aro (fecha o W6 da rodada 7) e a reversão tem conteúdo conhecido (`f68fa1b`). | Anotar na Task 15, junto ao comentário de reabertura, que está substituída pela Task 16 (feita e desfeita, só histórico), ou trocar o item por "substituída pela Task 16"; e, na Task 16, citar `f68fa1b` como o conteúdo de antes da Task 15. |

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
n.a. — 16 blocos em `## Decomposição` (≤16); a justificativa de dimensionamento lê `N/A`.

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
sem achados

## Minimal edit set (on FAIL)
### Edições no design
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
