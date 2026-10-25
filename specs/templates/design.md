# Design: <change title>

Change-ID: <same as spec>
Status: Draft            <!-- Approved only after consistency-gate PASS + human review -->
Spec: ./spec.md

## Approach summary
<!-- 3-6 sentences. A reviewer should grasp the shape of the solution here.
     Uma linha de abordagens: as 2–3 abordagens consideradas, a escolhida e por quê, uma frase cada. -->

## Stack & dependencies
<!-- New crates/libs/services with one-line justification each. Reference settled
     decisions in SOURCE-OF-TRUTH.md / the epic instead of re-arguing them. -->

## Data modeling
<!-- Schemas, types, table/object layout deltas. State tenant scoping mechanism explicitly. -->

## Interfaces & integration points
<!-- API shapes, message contracts, internal traits/modules touched.
     A claim about an artifact's class or propagation — portable vs local, generated vs authored,
     reaches an adopting repo or not — is measured here, never asserted. -->

## Seams sob teste
<!-- Onde os testes desta change observam comportamento. Um seam é a fronteira pública pela qual se
     observa comportamento sem alcançar o interno (Feathers) — ver `spec-layout` → convenções de
     linguagem. Três regras de escolha:
       1. Prefira seam EXISTENTE a novo.
       2. Use o seam MAIS ALTO que alcance o comportamento.
       3. O número ideal de seams NOVOS é um. Cada novo carrega justificativa.
     Sem superfície testável nesta change? Escreva "N/A — <motivo>" e mantenha a seção. -->

| Seam (onde) | Existente / novo | O que se observa através dele | Req IDs |
|---|---|---|---|
|  |  |  |  |

**Justificativa dos seams novos:** <uma linha por seam novo, ou "nenhum seam novo">

## Superfície heurística: código medido
<!-- Quando a spec declara uma superfície heurística (seção "Superfície heurística" da spec), esta seção
     traz, antes do Gate 1.5:
       - o código da superfície já prototipado — código, não prosa que o descreve;
       - o corpus de medida, por classe: as classes da spec, formas reais colhidas de transcrições ou do
         log das guardas, e os comandos que a própria change precisa rodar;
       - o comando de medida;
       - o resultado base × protótipo por forma, com o veredito esperado de cada uma.
     Regras: skill `consistency-gate`, seção "Superfície heurística" (dona única).
     Sem superfície heurística nesta change: escreva `N/A — <motivo>` e mantenha a seção. -->

## Dev-run premise
<!-- Mandatory when the change ships a runnable deliverable with UI; otherwise write
     "N/A — <reason>". Consumers: the visual review of the change (mandatory when any task is VISUAL) and
     mocked e2e (available, not required). The launch command must not depend on anything
     exclusive to the agent's session — the human must be able to run it as-is. -->
- Launch: <command that runs the deliverable locally (hot reload where applicable)>
- Mock/dev-flag strategy: <what replaces/bypasses each external dependency (backend, auth/Keycloak, ...)>
- Signed exception (Gate 1.5 only): <"none" — or reason + name + date, approved with the design>

## Requirement → design map
| Req ID | Design element that satisfies it |
|--------|----------------------------------|

## NFR mechanisms
<!-- For each N* in spec.md: what in this design makes the target plausible
     (by construction), and what test/benchmark proves it (by test). -->

## Failure modes & rollout
<!-- What breaks, how it degrades, how it ships (flags, migration, rollback). -->

## Decisions log
<!-- Choices made during brainstorming, with the option NOT taken and why.
     Run each entry through the three-criteria test in `specs/templates/adr.md` (the single source —
     the criteria are NOT restated here). Passes → write the ADR at `docs/adr/NNNN-<slug>.md` and leave
     the pointer here (`→ ADR NNNN`); the decision stops dying in the archive. Fails → it stays here,
     which is the common case. -->

## Assumptions
<!-- Must be empty or every line must also exist as a requirement/context line
     in spec.md. consistency-gate check 5 enforces this. -->

## Global Constraints
<!-- As restrições da spec que valem para toda task, uma por linha, com os valores literais. O executor as dá a
     cada implementador e revisor. Seção ANTES da `## Decomposição` — nunca dentro nem depois. -->

## Review Focus
<!-- Até 5 entradas ou modos de falha que a spec implica e que nenhum teste exerce, cada um com a task dona do
     teste que o cobre. Mesma regra de posição. -->

## Decomposição

**Justificativa de dimensionamento:** <motivo — obrigatória só acima de 16 blocos>

**Execução:** subagent-driven

<!-- As duas linhas acima ficam imediatamente abaixo do heading, ANTES deste comentário e FORA dele — é
     a primeira, não este comentário, que o check lê. Grafia exata do rótulo: `**Justificativa de
     dimensionamento:**` — sem indentação, dois pontos DENTRO do negrito, linha única (continuação em
     linhas seguintes não é lida). Obrigatória só quando a decomposição passa de 16 blocos `### Task
     N` — o alarme de 16 (não é teto); até lá o placeholder acima não bloqueia nada.
     Classificação do valor: `ausente` (nenhuma linha rotulada no trecho entre o heading e o primeiro
     bloco); `vazia` (sem texto, só espaços, ou igual a um placeholder — `<…>` (qualquer coisa entre
     `<` e `>` sem outro texto), `[SPECIFY]`, `TODO`, `N/A` — estes três últimos sem distinção de caixa);
     `presente` (qualquer outro texto). O check afere só PRESENÇA; o mérito da justificativa é
     julgado pelo `consistency-gate` e pelo humano — ver `spec-layout` → regra 2.

     `subagent-driven` é o padrão; `native` (o `executing-plans` do SP) é escolhido no Gate 1.5 — sem critério
     do kit além deste, a escolha é do humano.

     Um bloco `### Task N: <título>` por task de implementação, N a partir de 1, crescente, sem
     buracos (o ledger `tasks.md` é indexado por ele). Dentro de cada bloco, em qualquer ordem:
       - `**Refs:** <ids>` — OBRIGATÓRIA; os requisitos/NFRs que a task serve (ex.: `R1, R3-R5, N2`).
       - `**Visual:** sim` — só quando o entregável da task muda superfície de UI (a revisão visual
         da change, uma só, cobre as tasks marcadas).
       - `**Files:**`, `**Interfaces:**`, passos `- [ ]` — livres, para o executor.
     As duas linhas de fechamento (`validation-gate`, `sign-off`) NÃO são blocos: não são tasks de
     implementação, não entram no alarme de 16, e é o ledger (`tasks.md`) quem as escreve.
     Esta seção DEVE ser a última seção do arquivo — regra de forma, não de gosto: o extrator de
     briefs do Superpowers abre um bloco em `^#+ Task N` e só o fecha no próximo heading `Task`;
     qualquer seção escrita depois do último bloco seria engolida no brief da última task.
     A seção faz parte do conteúdo aprovado no Gate 1.5 (o digest cobre); o ledger `tasks.md` é
     gerado a partir dela por `check-tasks.sh --ledger <dir>` no início da implementação e fica fora
     do digest por ser estado derivado que muda durante a execução.
     Counting rule for every task: every counting command is proven against a known sample — in
     the baseline AND in the final state (a count that was never shown to match a known answer
     proves nothing; the lesson travels with the plan, which lives here).

     Exemplo (dentro deste comentário — não conta como bloco real):
       ### Task 1: Título curto do entregável
       **Refs:** R1, N2
       **Visual:** sim
       **Files:** Modify `path/to/file` (o que muda).
       - [ ] Passo 1
       - [ ] Passo 2
-->
