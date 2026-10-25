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

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
sem achados

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:47 ("onde ponteiros e ponto se sobrepõem no centro o alfa compõe (~0,84)") | No centro (51,50) sobrepõem-se **três** caminhos a 0,6 — ponteiro de horas, ponteiro de minutos e ponto central —, não dois: o alfa composto ali é 1 − 0,4³ ≈ 0,94, não ~0,84. O "efeito aceito" foi aceito sobre um número errado, e é exatamente o miolo do relógio que deveria parecer esmaecido no desligado (R3). | Corrigir para "até ~0,94 onde os dois ponteiros e o ponto se sobrepõem (~0,84 onde só dois)" ou, se o miolo quase cheio não for aceitável, tirar o ponto central do vazado / encurtar a origem dos ponteiros; registrar a decisão no Decisions log. |
| W2 | WARNING | design.md:72–73 (Dev-run premise: "no Gravity num slot que use o `SMALL_IMAGE`") | A spec (spec.md:31–32) diz que a ordem completa dos tipos dos slots do Gravity **ainda não foi lida**, e o Risco 4 (spec.md:79) prevê que nenhum dos dois mostradores use o `SMALL_IMAGE`. O design afirma como fato que o Gravity terá um slot no `SMALL_IMAGE`; se o Gravity também puser `MONOCHROMATIC_IMAGE` antes, o lançamento descrito não exercita o ramo colorido (R1/R5). | Reescrever: "no Gravity, se a lista do slot (lida por adb na Task 4) puser `SMALL_IMAGE` antes de `MONOCHROMATIC_IMAGE`; senão, num mostrador cujos slots só aceitem `SMALL_IMAGE` (Risco 4 da spec)". |
| W3 | WARNING | design.md:167–168 (Task 3 `**Refs:** R1, R2, R5, R6`) | A Task 3 liga `HOLLOW → aod_mono_hollow` e `STRUCK → aod_mono_struck` em `AodImage.monochromeIcon` e no ramo `MONOCHROMATIC_IMAGE` — sem ela R3 e R4 não aparecem no relógio —, mas só cita R2. A revisão visual e o ledger perdem o rastro de R3/R4 até a Task 3. | `**Refs:** R1, R2, R3, R4, R5, R6`. |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`; spec.md:89–91).

## Check 5 — Unstated assumptions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W4 | WARNING | design.md:50, design.md:119 (Decisions log "O mostrador pinta o recurso"), design.md:126 ("Assumptions: Nenhuma") | Todo o ramo monocromático (R1–R4) depende de o mostrador da OnePlus **carregar um `Icon` de recurso de outro pacote** (vector do APK do app) e pintá-lo. A spec só registra que o mostrador aplica a cor do tema à imagem monocromática; não diz nada sobre `Icon` de recurso × bitmap. O design anterior (archive `design.md:91`, `:207`) escolheu bitmap justamente para não depender do tratamento do `Icon` pelo mostrador. Aqui a dependência é afirmada sem modo de falha nem plano B: se o Chic não renderizar o recurso, o slot fica vazio — viola "Nenhum slot que hoje mostra a complication deixa de mostrá-la" (R1). | Registrar a premissa em `## Assumptions`; acrescentar em `## Failure modes & rollout` a linha "mostrador não renderiza `Icon` de recurso → slot vazio; conserto: `monochromeIcon` passa a rasterizar o vector branco (`Icon.createWithBitmap`, como `AodImage.icon` sem tint)"; e em `## Review Focus` "o Chic mostra as três formas a partir do `Icon` de recurso — Task 3". |

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
- design.md:47 → corrigir o alfa composto do centro para ~0,94 (três camadas) ou mudar a geometria do vazado (W1).
- design.md:70–74 → condicionar o uso do Gravity no `SMALL_IMAGE` à lista lida por adb, com o fallback do Risco 4 (W2).
- design.md:168 → `**Refs:** R1, R2, R3, R4, R5, R6` (W3).
- design.md:102–109, :124–126, :140–145 → premissa do `Icon` de recurso, modo de falha com fallback para bitmap branco e linha de Review Focus (W4).
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
