# Spec: Complication do AOD em texto curto (`SHORT_TEXT`), com o relógio e "AOD"/"OFF"/"---"

Change-ID: 2026-10-complication-short-text
Status: Approved
<!-- approved-by: Ricardo Nogueira on 2026-10-25 -->
<!-- approved-content: sha256:558aae21830b -->
Epic: none
Author(s): ricardo with Claude
Date: 2026-10-25

## Problem & leverage

Nos mostradores Gravity e "Chic", a "AOD Toggle" chega como imagem (monocromática): o desenho "AOD" num
disco que o mostrador desenha atrás dos slots de imagem; o estado só aparece pela forma (sólido, vazado,
tarja). As complications vizinhas (temperatura, batimento) mostram um ícone pequeno e um texto no estilo
de fonte do mostrador. O autor quer que a "AOD Toggle" fique parecida com elas: o relógio pequeno como
ícone e o estado escrito — "AOD" ligado, "OFF" desligado, "---" indisponível.

**Alavanca.** O tipo **texto curto** (`SHORT_TEXT`) é o único, entre os que estes mostradores desenham para
um app de fora da OnePlus, que mostra ícone e texto juntos; o mostrador escolhe o tipo pela lista do slot
(o app não escolhe por slot), e o texto curto vem antes da imagem monocromática nessa lista. A imagem
monocromática e o `SMALL_IMAGE` seguem como alternativas para slots que não aceitem o texto curto, e a
complication não some de nenhum mostrador. Sem esta change, o estado continua só pela forma.

**Contexto (SoT, change anterior arquivada em `specs/archive/2026-10-25-2026-10-complication-monochrome/` e
experimento descartável de 2026-10-25).** Estado, toque, atualização periódica, imagem monocromática e
`SMALL_IMAGE` estão no `SOURCE-OF-TRUTH.md` e não mudam aqui. Lido por adb: os slots 1–3 do Gravity e do
Chic listam `GOAL_PROGRESS, RANGED_VALUE, SHORT_TEXT, MONOCHROMATIC_IMAGE, SMALL_IMAGE`. O experimento
(uma cópia do app fora do repositório, instalada como debug) mostrou:
- os dois mostradores têm desenhos dedicados aos provedores da OnePlus (batimento, temperatura, UV…),
  escolhidos pelo componente do provedor — o visual do batimento (número + ícone na abertura do anel) não
  é alcançável por outro app; para os demais provedores usam desenhos genéricos por tipo;
- o anel genérico (`RANGED_VALUE`) mostra uma coisa só no centro (a imagem, se houver; senão o texto),
  ignora a escala de cores (sem opacidade) e, no Chic, sai grosso e com o texto grande — descartado pelo
  autor;
- o texto curto mostra o relógio pequeno em cima, na cor do tema, e o texto embaixo, em branco: no Chic
  com a mesma borda fina e a mesma fonte das vizinhas; no Gravity sobre o disco cinza dos slots que não
  são anel.

## Requirements (functional)

| ID | Requirement | Tenant scope (indústria / grupo / distribuidora / n.a.) | Acceptance criterion (how a reviewer verifies it) |
|----|-------------|---------------------------------------------------------|---------------------------------------------------|
| R1 | A complication é oferecida também como **texto curto** (`SHORT_TEXT`), além da imagem monocromática e do `SMALL_IMAGE`; uma complication só no seletor; o mostrador escolhe o tipo de cada slot e o app responde no tipo pedido. O anel de valor (`RANGED_VALUE`) não é oferecido. | n.a. | No Gravity e no Chic, recolocada num dos slots 1–3, a complication aparece como texto curto (ícone em cima, texto embaixo); o seletor lista uma só "AOD Toggle". Nenhum slot que hoje mostra a complication deixa de mostrá-la. |
| R2 | No texto curto, o **ligado** mostra o texto **"AOD"** e o relógio **sólido** como ícone. | n.a. | Com o AOD ligado, aparece "AOD" com o relógio sólido, a olho no relógio. Teste de unidade do mapeamento estado → (texto, ícone). |
| R3 | No texto curto, o **desligado** mostra o texto **"OFF"** e o relógio **esmaecido** (60%, como no vazado da imagem monocromática). | n.a. | Com o AOD desligado, aparece "OFF" com o relógio esmaecido, distinguível do ligado a olho. Teste de unidade do mapeamento. |
| R4 | No texto curto, o **indisponível** mostra o texto **"---"** e o mesmo relógio esmaecido do desligado. | n.a. | Sem a permissão, aparece "---" com o relógio esmaecido, distinguível do desligado a olho. Teste de unidade do mapeamento. |
| R5 | A imagem monocromática e o `SMALL_IMAGE` não mudam. | n.a. | NO-TASK: preservação — os testes de unidade existentes das formas e das cores continuam verdes; num slot que use um desses tipos, a complication aparece como antes. |
| R6 | Toque e atualização funcionam igual nos três tipos: ligado/desligado alterna; indisponível só reavalia e redesenha; atualização periódica de 5 min enquanto num mostrador ativo. | n.a. | Num slot com o texto curto: tocar alterna o AOD (Configurações acompanha) e o texto troca entre "AOD" e "OFF"; indisponível + `pm grant` + toque redesenha sem alternar. |
| R7 | Testes de unidade cobrem o mapeamento de cada estado (ligado, desligado, indisponível por permissão e por chave ausente) para o texto e a forma do ícone. | n.a. | `./gradlew testDebugUnitTest` passa e o relatório tem um caso por estado e por causa de indisponível. |
| R8 | A lista de verificação manual cobre R1–R4 e R6 no relógio real, no Gravity e no Chic, e é executada; os resultados vão para o `evidence.md` desta change. | n.a. | A lista atualizada e seus resultados (mostradores, tipo usado em cada um, data, cada item OK/falha) estão no `evidence.md`. |

## Non-functional requirements

| ID | Category | Target (number or explicit "no target") | How it will be measured |
|-----|---------------------|------------------------------|--------------------------|
| N1 | Latency             | ≤ 1 s do toque até o novo estado visível no texto curto. | Item da lista manual (observação no relógio). |
| N2 | Throughput / volume | No target (um usuário, uma troca por vez). | — |
| N3 | Tenant isolation    | n.a. — app pessoal, sem dados de tenant, sem rede. | Verificado por N4. |
| N4 | Security / authn-z  | O app continua pedindo **apenas** `WRITE_SECURE_SETTINGS`. | `aapt dump permissions` do APK de release. |
| N5 | Observability       | Sem mudança: falhas geram uma linha na tag `AodToggle`; o caminho feliz não registra nada, também no texto curto. | Item da lista manual (`adb logcat -s AodToggle`). |
| N6 | Energia             | Sem trabalho novo em segundo plano: mesma atualização periódica de 5 min; nenhum serviço, alarme ou job próprio. | `dumpsys alarm` / `dumpsys jobscheduler` sem o pacote. |

## Superfície heurística

N/A — a change não altera hook nem check do kit; nada aqui classifica texto livre por padrão.

## Out of scope

- O anel de valor (`RANGED_VALUE`): testado no experimento e descartado pelo autor; `GOAL_PROGRESS` e os demais tipos.
- Mudar a imagem monocromática ou o `SMALL_IMAGE`.
- Título (segunda linha) e textos além de "AOD", "OFF" e "---".
- Relógio com tarja no texto curto (o indisponível usa o relógio esmaecido do desligado).
- Imagem própria para o modo ambiente.
- A tela do gatilho e o ícone do app.
- Cor, fonte, borda e fundo do texto curto (são do mostrador; o disco cinza do Gravity fica).
- Uma segunda complication no seletor, ou escolher o tipo por slot.

## Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| Slots já configurados mantêm o tipo escolhido antes da atualização. | A complication continua como imagem até ser recolocada. | A lista manual recoloca a complication antes de verificar; o README orienta (já orienta, da change anterior). |
| O relógio esmaecido a 60% pode ficar sutil demais no tamanho do ícone. | Ligado e desligado se distinguem só pelo texto. | Aceito: o texto ("AOD"/"OFF") já distingue; a revisão visual julga o ícone. |
| Outro mostrador pode desenhar o texto curto sem o ícone, ou cortar o texto. | O estado depende só do texto, ou some. | Verificado no Gravity e no Chic; outros mostradores ficam fora da verificação. |

## Seções do SoT afetadas

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Estado atual | R1–R6 |
| Arquitetura | R1–R4, R7 |

## Epic invariants that apply

Nenhum — change sem épico.

## Open questions

Nenhuma.
