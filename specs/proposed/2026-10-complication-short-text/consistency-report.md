# Consistency Report — 2026-10-complication-short-text

Verdict: FAIL
**Justificativa de tamanho:** <motivo — obrigatória só acima de 100 linhas>

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 1        | 3       | 0           | —    |

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:186-189 (Task 4, item README) | A Task 4 cita só R8 (a lista manual), mas também reescreve o README para descrever o visual novo; nenhum R pede isso, e o Risco 1 da spec diz que o README "já orienta". A edição do README fica sem requisito que a motive. | Ligar o item do README ao Risco 1 da spec na Task 4 (e no mapa), ou remover o item. |

## Check 3 — Contradictions
sem achados

## Check 4 — Epic invariants
n.a. — change sem épico (spec: `Epic: none`; "Nenhum — change sem épico").

## Check 5 — Unstated assumptions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W2 | WARNING | design.md:18-27, 133 (Protótipo medido; Decisions log "Ícone em bitmap branco") | O protótipo medido usou `Icon` de recurso e só o relógio sólido; a abordagem escolhida (bitmap branco via `rasterize`, e a versão esmaecida com alfa 0,6) não foi medida no `SHORT_TEXT`. O design supõe, sem dizer, que o mostrador desenha o bitmap no slot do ícone do texto curto e preserva o alfa — o próprio Contexto da spec registra que o anel genérico ignorou a opacidade. Se o alfa cair, R3/R4 ("relógio esmaecido") falham no relógio. | Repetir o experimento descartável com `Icon.createWithBitmap` dos dois vectors (sólido e esmaecido) no Gravity e no Chic e registrar o resultado em "Protótipo medido"; se não medir, escrever a suposição em `## Assumptions` e levá-la ao humano no Gate 1.5. |

## Check 6 — Verifiability
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W3 | WARNING | spec.md:49 (R6) × design.md:190 (Task 4) | R6 exige "atualização periódica de 5 min" no texto curto, mas o aceite de R6 só observa toque e redesenho; a lista da Task 4 cobre R6 sem item para a atualização periódica (na change anterior o item equivalente, M7, foi dispensado). A parte periódica de R6 fica sem verificação nomeada. | Na Task 4, acrescentar item que verifique a atualização periódica no texto curto (mudança em Configurações aparece em ≤ ~5 min) ou, no mínimo, o `UPDATE_PERIOD_SECONDS=300` no APK por `aapt2 dump xmltree`, e citá-lo no mapa de R6. |

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
n.a. — 4 blocos em `## Decomposição` (≤16) e justificativa de dimensionamento `N/A`.

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| B1 | BLOCKING | design.md:72-75 (`## Seams sob teste`) | R5 é requisito funcional sobre superfície testável (preservação da imagem monocromática e do `SMALL_IMAGE`, aceite pelos testes de unidade existentes de `monochromeFormOf`/`presentationOf` e pelo slot no relógio), e nenhum seam o lista em Req IDs; a regra do check 8 exige ao menos um seam nomeado por R funcional. | Acrescentar R5 aos Req IDs do seam "API pública do núcleo" (testes existentes de `monochromeFormOf`/`presentationOf`) e do seam "O relógio real (lista manual)". |

## Minimal edit set (on FAIL)
### Edições no design
- design.md:74-75 (`## Seams sob teste`) → incluir R5 nos Req IDs das duas linhas (B1).
- design.md:22-27 (Protótipo medido) → medir bitmap branco sólido e esmaecido no `SHORT_TEXT` do Gravity e do Chic, ou declarar a suposição em `## Assumptions` (W2).
- design.md:190 (Task 4) e design.md:101 (mapa, R6) → item da lista para a atualização periódica de 5 min no texto curto (W3).
- design.md:186-189 (Task 4) → ligar o item do README ao Risco 1 da spec ou removê-lo (W1).
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
