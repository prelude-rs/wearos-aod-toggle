# Consistency Report — 2026-10-complication-monochrome

Verdict: PASS
<!-- Verdict: PASS | FAIL — the consistency-gate writes this. MUST be the first `^Verdict:` line;
     hooks/CI read the VALUE (comment stripped). Never translate the token.
     Keep the comment OFF the value's line: on it, the token inside the comment defeats the read.
     How the value is derived: the `consistency-gate` skill, section "Output". -->
**Justificativa de tamanho:** <motivo — obrigatória só acima de 100 linhas>
<!-- Quando esta linha é exigida e o que conta como vazia: skill `consistency-gate`, seção "Output". -->

## Rodadas
<!-- Uma linha por rodada do gate: número, veredito, contagens (BLOCKING, WARNING, reaberturas) e a base.
     A coluna Base e a linha de decisão de parada sob a tabela: skill `consistency-gate`, seção "Output". -->
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | PASS    | 0        | 4       | 0           | —    |
| 2 | PASS    | 0        | 1       | 0           | b0b7513 |

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
sem achados

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:85 (mapa, linha R2: "`aod_text` como `Icon` de recurso") | O delta trocou o `Icon` de recurso por bitmap branco (design.md:51, :121, :175); a linha do mapa, fora do delta, ficou com a forma antiga e contradiz a linha 51. Quem implementa a Task 3 pelo mapa cria `Icon.createWithResource` e reabre o risco do antigo W4. | Reescrever a linha para "`aod_text` rasterizado em bitmap branco (`monochromeIcon`)". |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`).

## Check 5 — Unstated assumptions
sem achados

## Check 6 — Verifiability
sem achados

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
n.a. — 4 blocos em `## Decomposição` (≤16); justificativa de dimensionamento `N/A`.

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
sem achados

## Minimal edit set (on FAIL)
### Edições no design
- design.md:85 → trocar "`Icon` de recurso" por bitmap branco rasterizado (W1).
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
