# Spec: <change title>

Change-ID: <yyyy-mm-short-name>
Status: Draft            <!-- Draft | In Review | Approved — only a human writes Approved -->
Epic: <link to specs/epics/NNN-*.md, or "none">
Author(s): <human> with Claude
Date: <date>

## Problem & leverage
<!-- The CEO-review block. What problem, for whom, what happens if we don't build it.
     Is this the highest-leverage version of the request? If a simpler change captures
     most of the value, say so here and justify the chosen scope. -->

## Requirements (functional)
<!-- Numbered, atomic, verifiable. One behavior per requirement.
     A spec nomeia O QUÊ, não o ONDE-DENTRO (CONTEXT.md → "onde-dentro"; esta é a fonte da regra):
       PODE nomear: o entregável pelo papel ("o gate de arquivamento") ou pelo arquivo quando o arquivo
         É o entregável (um hook, um template); comandos públicos de verificação do projeto.
       NÃO PODE nomear: linha de arquivo (`x.sh:42`), nome de função ou variável, comando literal que
         alcança o interno, estrutura interna.
     O critério de aceite diz o que um revisor OBSERVA, nunca por onde ele observa. O alarme do
     check-tasks.sh aponta (aviso) cada aceite que cruza a fronteira; o consistency-gate (6b) julga.
     Each requirement MUST name its tenant scope where relevant.
     Measure every acceptance criterion against the baseline BEFORE implementing: one that already
     passes is vacuous, and the requirement it serves proves nothing.
     If the change edits a source whose generated/derived copy is verified elsewhere, that sync is an
     acceptance criterion here — not a consequence. Otherwise every R* passes while the external
     verification breaks. -->

| ID | Requirement | Tenant scope (indústria / grupo / distribuidora / n.a.) | Acceptance criterion (how a reviewer verifies it) |
|----|-------------|---------------------------------------------------------|---------------------------------------------------|
| R1 |             |                                                         |                                                    |

## Non-functional requirements

| ID | Category | Target (number or explicit "no target") | How it will be measured |
|-----|---------------------|------------------------------|--------------------------|
| N1 | Latency             |                              |                          |
| N2 | Throughput / volume |                              |                          |
| N3 | Tenant isolation    | No cross-tenant data access  | (mandatory row — state the verification) |
| N4 | Security / authn-z  |                              |                          |
| N5 | Observability       |                              |                          |

## Superfície heurística
<!-- Superfície heurística (CONTEXT.md → "superfície heurística"): a parte de um hook ou check que
     classifica texto livre por padrão — o comando Bash numa guarda, o julgamento de um caminho, a regex
     de um check de forma —, em que nenhuma lista de formas é completa. Se esta change altera uma, esta
     seção carrega:
       - as classes de formas que o corpus de medida tem de cobrir;
       - o contrato por classe, nas duas direções: o que cada classe libera e o que ela nega.
     A lista de formas vive no teste, nunca aqui. Uma forma nova que cai numa classe declarada não
     reabre o Gate 1: liberar o que a classe nega → BLOCKING (caso de teste + código);
     negar o que a classe libera → WARNING (Fog do épico). Só uma classe nova reabre o Gate 1.
     Regras: skill `consistency-gate`, seção "Superfície heurística" (dona única).
     Sem superfície heurística nesta change: escreva `N/A — <motivo>` e mantenha a seção. -->

## Out of scope
<!-- MANDATORY and non-empty. The most important section for controlling the agent.
     List the adjacent things we are deliberately NOT doing in this change. -->

## Seções do SoT afetadas

<!-- Uma linha por seção do `specs/SOURCE-OF-TRUTH.md` que esta change altera, identificada pelo texto
     literal do heading (nível 1 a 3; o que vem antes do primeiro heading pertence a ele), com os
     requisitos que motivam a alteração. O gate de arquivamento afere nos DOIS sentidos: seção declarada
     sem toque reprova; seção tocada sem declaração reprova. Uma seção removida declara-se sob a seção
     anterior. Sem delta no SoT: apague a tabela e escreva, no início de uma linha,
     `SOT-NO-DELTA: <motivo>` (motivo não vazio). Fonte da regra: spec-layout → regra 5(b). -->

| Seção do SoT (heading literal) | Req IDs |
|---|---|
|  |  |

## Epic invariants that apply
<!-- Copy the relevant invariant IDs from the parent epic. consistency-gate checks these. -->

## Open questions
<!-- Anything unresolved. Must be empty before Status can become Approved. -->
