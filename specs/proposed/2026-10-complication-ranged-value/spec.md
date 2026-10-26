# Spec: Complication do AOD com anel de valor (`RANGED_VALUE`), como o batimento cardíaco

Change-ID: 2026-10-complication-ranged-value
Status: Draft            <!-- Draft | In Review | Approved — only a human writes Approved -->
Epic: none
Author(s): ricardo with Claude
Date: 2026-10-25

## Problem & leverage

Nos mostradores Gravity e "Chic", as complications de temperatura e de batimento cardíaco chegam como
`RANGED_VALUE`: o mostrador desenha um **anel de valor** (arco proporcional ao valor), o valor em texto no
centro e um ícone pequeno embaixo, sobre fundo preto. A "AOD Toggle" chega como imagem (monocromática),
num disco cinza que o mostrador desenha atrás dos slots de imagem, e destoa das vizinhas. O autor quer
que ela tenha a mesma cara do batimento cardíaco: anel cheio com o AOD ligado, vazio com ele desligado,
o texto "AOD" no centro e o relógio pequeno embaixo.

**Alavanca.** Não há versão menor: o anel e o fundo preto só existem no tipo `RANGED_VALUE`, e o
mostrador escolhe o tipo pela lista do slot — o app não escolhe por slot. Ao declarar o anel de valor, os
slots que o aceitam antes da imagem passam a usá-lo; a imagem monocromática e o `SMALL_IMAGE` seguem
como alternativas para os slots que não aceitam o anel, e a complication não some de nenhum mostrador.
Sem esta change, a complication segue no disco cinza.

**Contexto (SoT e change anterior, arquivada em `specs/archive/2026-10-25-2026-10-complication-monochrome/`).**
Estado, toque, atualização periódica, imagem monocromática e `SMALL_IMAGE` estão no `SOURCE-OF-TRUTH.md`
e não mudam aqui. Lido por adb em 2026-10-25: os slots 1–3 do Gravity e do Chic listam
`GOAL_PROGRESS, RANGED_VALUE, SHORT_TEXT, MONOCHROMATIC_IMAGE, SMALL_IMAGE`; o batimento cardíaco da OnePlus
envia `RANGED_VALUE` com `min=0`, `max=220`, o valor em texto e um ícone monocromático.

## Requirements (functional)

| ID | Requirement | Tenant scope (indústria / grupo / distribuidora / n.a.) | Acceptance criterion (how a reviewer verifies it) |
|----|-------------|---------------------------------------------------------|---------------------------------------------------|
| R1 | A complication é oferecida também como **anel de valor** (`RANGED_VALUE`), além da imagem monocromática e do `SMALL_IMAGE`; uma complication só no seletor; o mostrador escolhe o tipo de cada slot e o app responde no tipo pedido. | n.a. | No Gravity e no Chic, recolocada num dos slots 1–3, a complication aparece com o anel de valor, sobre fundo preto como as vizinhas; o seletor lista uma só "AOD Toggle". Nenhum slot que hoje mostra a complication deixa de mostrá-la. |
| R2 | No anel de valor, o **ligado** é o anel **cheio**, o texto "AOD" no centro e o relógio **sólido** como ícone pequeno. | n.a. | Com o AOD ligado, o anel aparece cheio, com "AOD" e o relógio sólido, a olho no relógio. Teste de unidade do mapeamento estado → (valor, texto, ícone). |
| R3 | No anel de valor, o **desligado** é o anel **vazio**, o texto "AOD" e o relógio **esmaecido** (60%, como no vazado da imagem monocromática). | n.a. | Com o AOD desligado, o anel aparece vazio e se distingue do cheio a olho no Gravity e no Chic (o mostrador desenha a trilha do anel de modo que vazio e cheio não se confundam); relógio esmaecido. Teste de unidade do mapeamento. |
| R4 | No anel de valor, o **indisponível** é o anel **vazio**, o texto **"---"** no lugar de "AOD" e o mesmo relógio **esmaecido** do desligado. | n.a. | Sem a permissão, o anel aparece vazio com "---" e o relógio esmaecido, distinguível do desligado a olho pelo texto. Teste de unidade do mapeamento. |
| R5 | A imagem monocromática e o `SMALL_IMAGE` não mudam. | n.a. | NO-TASK: preservação — os testes de unidade existentes das formas e das cores continuam verdes; num slot que use um desses tipos, a complication aparece como antes. |
| R6 | Toque e atualização funcionam igual nos três tipos: ligado/desligado alterna; indisponível só reavalia e redesenha; atualização periódica de 5 min enquanto num mostrador ativo. | n.a. | Num slot com o anel de valor: tocar alterna o AOD (Configurações acompanha) e o anel enche/esvazia; indisponível + `pm grant` + toque redesenha sem alternar. |
| R7 | Testes de unidade cobrem o mapeamento de cada estado (ligado, desligado, indisponível por permissão e por chave ausente) para o valor do anel, o texto e a forma do ícone. | n.a. | `./gradlew testDebugUnitTest` passa e o relatório tem um caso por estado e por causa de indisponível. |
| R8 | A lista de verificação manual cobre R1–R4 e R6 no relógio real, no Gravity e no Chic, e é executada; os resultados vão para o `evidence.md` desta change. | n.a. | A lista atualizada e seus resultados (mostradores, tipo usado em cada um, data, cada item OK/falha) estão no `evidence.md`. |

## Non-functional requirements

| ID | Category | Target (number or explicit "no target") | How it will be measured |
|-----|---------------------|------------------------------|--------------------------|
| N1 | Latency             | ≤ 1 s do toque até o novo estado visível no anel de valor. | Item da lista manual (observação no relógio). |
| N2 | Throughput / volume | No target (um usuário, uma troca por vez). | — |
| N3 | Tenant isolation    | n.a. — app pessoal, sem dados de tenant, sem rede. | Verificado por N4. |
| N4 | Security / authn-z  | O app continua pedindo **apenas** `WRITE_SECURE_SETTINGS`. | `aapt dump permissions` do APK de release. |
| N5 | Observability       | Sem mudança: falhas geram uma linha na tag `AodToggle`; o caminho feliz não registra nada, também no anel de valor. | Item da lista manual (`adb logcat -s AodToggle`). |
| N6 | Energia             | Sem trabalho novo em segundo plano: mesma atualização periódica de 5 min; nenhum serviço, alarme ou job próprio. | `dumpsys alarm` / `dumpsys jobscheduler` sem o pacote. |

## Superfície heurística

N/A — a change não altera hook nem check do kit; nada aqui classifica texto livre por padrão.

## Out of scope

- `GOAL_PROGRESS` (vem antes do `RANGED_VALUE` na lista do Gravity e do Chic: declarado, seria o escolhido), `SHORT_TEXT` e os demais tipos.
- Mudar a imagem monocromática ou o `SMALL_IMAGE`.
- Título, ou texto além de "AOD" (ligado e desligado) e "---" (indisponível): nada de "ON"/"OFF" nem número.
- Relógio com tarja no anel de valor (o indisponível usa o mesmo relógio esmaecido do desligado).
- Imagem própria para o modo ambiente.
- A tela do gatilho e o ícone do app.
- Cor e estilo do anel de valor (são do mostrador).
- Uma segunda complication no seletor, ou escolher o tipo por slot.

## Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| Com a faixa 0–1, o mostrador pode desenhar o anel de modo estranho (sem a trilha de fundo, ou vazio indistinguível do cheio). | R3 não se cumpre. | Conta como "não ficou bom": a faixa passa a 0–100 (decisão do autor, 2026-10-25); medido no relógio no design. |
| Slots já configurados mantêm o tipo escolhido antes da atualização. | A complication continua como imagem até ser recolocada. | A lista manual recoloca a complication antes de verificar; o README orienta (já orienta, da change anterior). |
| O mostrador pode mostrar outra coisa no lugar do ícone pequeno (como os "14 22" da temperatura no Gravity). | O relógio não aparece; ligado e desligado se distinguem só pelo anel. | Verificado na lista manual; se ligado e desligado ficarem indistinguíveis, a spec é reaberta. |
| O mostrador pode cortar ou reduzir o texto "---". | O indisponível se confunde com o desligado. | Verificado na lista manual; se ficarem indistinguíveis, a spec é reaberta. |

## Seções do SoT afetadas

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Estado atual | R1–R6 |
| Arquitetura | R1–R4, R7 |

## Epic invariants that apply

Nenhum — change sem épico.

## Open questions

Nenhuma.
