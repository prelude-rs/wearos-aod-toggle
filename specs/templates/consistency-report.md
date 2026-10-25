# Consistency Report — <change-id>

Verdict: PENDING
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
| 1 |         |          |         |             | —    |

<!-- A partir daqui: um heading `## Check …` por check, na ordem abaixo, com o corpo da rodada atual:
     `sem achados`, `n.a. — <motivo>` ou a tabela de achados (forma: ver o Check 3). Exemplo de linha:
       | B1 | BLOCKING | design.md:76 | <por que morde aqui> | <conserto proposto> |
     Regras: skill `consistency-gate`, seção "Output". -->

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
sem achados

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|

## Check 4 — Epic invariants
sem achados

## Check 5 — Unstated assumptions
sem achados

## Check 6 — Verifiability
sem achados

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
<!-- Com mais de 16 blocos em `## Decomposição` e a linha `**Justificativa de dimensionamento:**`
     presente: o julgamento da justificativa contra o critério por espécie da regra 2 do `spec-layout`,
     registrado como achado (tabela acima) quando ela descreve mais de um entregável ou mais de um
     estado verde final. -->
n.a. — <motivo> (≤16 blocos, ou sem justificativa de dimensionamento)

## Check 7 — Dev-run premise (UI)
<!-- Existe e está preenchida quando a change entrega UI? Ou `n.a. — <motivo>`. -->
n.a. — <motivo>

## Check 8 — Seams sob teste
<!-- Todo `R*` funcional com superfície testável mapeia um seam nomeado; seam novo com justificativa;
     nenhum seam observando por canal lateral. Sem superfície testável → `n.a. — <motivo>`. -->
n.a. — <motivo>

## Minimal edit set (on FAIL)
### Edições no design
<!-- uma linha por edição: sítio → o quê -->
### Reabertura do Gate 1
<!-- SÓ por CONTRADICTION (entre requisitos, ou requisito × premissa), UNVERIFIABLE (critério que
     nenhum revisor consegue observar) ou OVERSPECIFIED (aceite que cruza a fronteira do onde-dentro —
     achado do 6b/alarme). Redação, estilo, "alinhar ao design" NUNCA. Uma linha por item:
     `- <R* | Premissa N | I*> — motivo: CONTRADICTION | UNVERIFIABLE | OVERSPECIFIED — <o quê>`;
     um item OVERSPECIFIED cita entre crases o trecho que o alarme/6b marcou e a reescrita (`<trecho> →
     <o que o revisor observa>`), senão o check o reprova (sem a amarra, OVERSPECIFIED vira "redação"
     com outro nome). Cada item exige re-transcrição humana. -->
Reaberturas do Gate 1 propostas: 0
