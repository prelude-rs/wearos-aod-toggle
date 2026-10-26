# Spec: Complication do AOD em imagem monocromática, na cor do tema do mostrador

Change-ID: 2026-10-complication-monochrome
Status: Approved
<!-- approved-by: Ricardo Nogueira on 2026-10-25 -->
<!-- approved-content: sha256:ab8ed36a8fb3 -->
Epic: none
Author(s): ricardo with Claude
Date: 2026-10-25

## Problem & leverage

Hoje a complication "AOD Toggle" só se oferece como imagem colorida (`SMALL_IMAGE`): âmbar, branca ou
cinza, cores fixas que não conversam com o resto do mostrador. Os mostradores da OnePlus têm uma **cor
do tema**, que aplicam às complications entregues como **imagem monocromática**. O autor quer que a
complication harmonize com o tema do mostrador nos três estados.

Na imagem monocromática o mostrador pinta tudo com a cor do tema, então o estado não pode mais vir da
cor: vem da **forma** — sólido, vazado e **tarja**. O autor aceita esse custo nos mostradores que
preferirem a imagem monocromática.

**Alavanca.** Não há versão menor: só a imagem monocromática recebe a cor do tema (o app não sabe qual é
a cor do tema), e o `SMALL_IMAGE` continua para os slots que não aceitam a monocromática, de modo que a
complication não some de nenhum mostrador. Sem esta change, a complication segue com as cores fixas.

**Contexto (SoT e change anterior, arquivada em `specs/archive/2026-10-25-2026-10-aod-toggle-complication/`).**
O comportamento de estado, toque, atualização periódica e gatilho está no `SOURCE-OF-TRUTH.md` e não
muda aqui. Quem escolhe o tipo de complication de cada slot é o mostrador, pela ordem da lista de tipos
do slot, uma vez, ao configurar; o app responde no tipo pedido. Lido por adb em 2026-10-25: os slots 1–3
do mostrador "Chic" (`com.oplus.wearos.watchface.zhenmo.style`) listam
`GOAL_PROGRESS, RANGED_VALUE, SHORT_TEXT, MONOCHROMATIC_IMAGE, SMALL_IMAGE`; os slots do Gravity aceitam
`SMALL_IMAGE` (a ordem completa ainda não foi lida).

## Requirements (functional)

| ID | Requirement | Tenant scope (indústria / grupo / distribuidora / n.a.) | Acceptance criterion (how a reviewer verifies it) |
|----|-------------|---------------------------------------------------------|---------------------------------------------------|
| R1 | A complication é oferecida aos mostradores como **imagem monocromática** e como imagem colorida (`SMALL_IMAGE`); o mostrador escolhe o tipo de cada slot, e o app responde no tipo pedido. | n.a. | Num slot cuja lista põe a imagem monocromática antes do `SMALL_IMAGE`, a complication aparece na cor do tema; num slot que só aceita `SMALL_IMAGE`, aparece colorida como hoje. Nenhum slot que hoje mostra a complication deixa de mostrá-la. |
| R2 | Na imagem monocromática, o **ligado** é a arte "AOD" de hoje (A, relógio, D) toda sólida. | n.a. | Com o AOD ligado, a complication monocromática mostra A, relógio e D cheios, na cor do tema. Teste de unidade do mapeamento estado → forma. |
| R3 | Na imagem monocromática, o **desligado** tem A e D **vazados** (só o contorno) e o relógio a **60%** de opacidade. | n.a. | Com o AOD desligado, a complication monocromática mostra A e D vazados e o relógio esmaecido, distinguível do ligado a olho no relógio. Teste de unidade do mapeamento. |
| R4 | Na imagem monocromática, o **indisponível** é igual ao desligado com uma **tarja** diagonal por cima, cercada de uma **folga transparente** que a separa do desenho (a "tarja com folga" da prévia aprovada pelo autor em 2026-10-25). | n.a. | Sem a permissão, a complication monocromática mostra o desenho do desligado cortado pela tarja, distinguível do desligado a olho no relógio. Teste de unidade do mapeamento. |
| R5 | A imagem colorida (`SMALL_IMAGE`) não muda: arte cheia, âmbar ligado, branca desligado, cinza indisponível. | n.a. | NO-TASK: preservação — num slot que usa o `SMALL_IMAGE`, as três cores aparecem como antes; os testes de unidade existentes das cores continuam verdes. |
| R6 | Toque e atualização da complication funcionam igual nos dois tipos: ligado/desligado alterna; indisponível só reavalia e redesenha; atualização periódica de 5 min enquanto num mostrador ativo. | n.a. | Num slot com a imagem monocromática: tocar alterna o AOD (Configurações acompanha) e a forma muda (sólido ↔ vazado); indisponível + `pm grant` + toque redesenha sem alternar; uma mudança feita em Configurações aparece em até ~5 min com a tela ligada. |
| R7 | Testes de unidade cobrem o mapeamento de cada estado (ligado, desligado, indisponível por permissão e por chave ausente) para a forma da imagem monocromática. | n.a. | `./gradlew testDebugUnitTest` passa e o relatório tem um caso por estado e por causa de indisponível. |
| R8 | A lista de verificação manual cobre R1–R6 no relógio real, num mostrador que usa a imagem monocromática e num que usa o `SMALL_IMAGE`, e é executada; os resultados vão para o `evidence.md` desta change. | n.a. | A lista atualizada e seus resultados (mostradores, tipo usado em cada um, data, cada item OK/falha) estão no `evidence.md`. |

## Non-functional requirements

| ID | Category | Target (number or explicit "no target") | How it will be measured |
|-----|---------------------|------------------------------|--------------------------|
| N1 | Latency             | ≤ 1 s do toque até a nova forma visível, também na imagem monocromática (mesma meta da complication de hoje). | Item da lista manual, no mostrador que usa a monocromática. |
| N2 | Throughput / volume | No target (um usuário, uma troca por vez). | — |
| N3 | Tenant isolation    | n.a. — app pessoal, sem dados de tenant, sem rede. | Verificado por N4. |
| N4 | Security / authn-z  | O app continua pedindo **apenas** `WRITE_SECURE_SETTINGS`. | `aapt dump permissions` do APK de release. |
| N5 | Observability       | Sem mudança: falhas geram uma linha na tag `AodToggle`; o caminho feliz não registra nada, também no tipo monocromático. | Item da lista manual (`adb logcat -s AodToggle`). |
| N6 | Energia             | Sem trabalho novo em segundo plano: o tipo monocromático usa a mesma atualização periódica de 5 min; nenhum serviço, alarme ou job próprio. | `dumpsys alarm` / `dumpsys jobscheduler` sem o pacote; `dumpsys batterystats` com a complication monocromática num mostrador por ~1 h: acionamentos na mesma ordem dos medidos com o `SMALL_IMAGE` (≤ ~12/h). |

## Superfície heurística

N/A — a change não altera hook nem check do kit; nada aqui classifica texto livre por padrão.

## Out of scope

- A tela do gatilho e o ícone do app: continuam como estão (cores e arte de hoje).
- Imagem própria para o modo ambiente: o mostrador decide como desenhar a complication no AOD.
- Outros tipos de complication (`SHORT_TEXT`, `RANGED_VALUE` e afins).
- Escolher o tipo por slot ou forçar o colorido onde o mostrador prefere a monocromática: quem escolhe é
  o mostrador; o app só declara os dois.
- Descobrir ou ler a cor do tema no app.
- Mudar a imagem colorida (`SMALL_IMAGE`) — inclusive aplicar a ela as formas vazado/tarja.

## Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| Nos slots que preferem a monocromática (o Chic, pela lista lida), a complication perde o âmbar e o branco. | O estado passa a ser lido pela forma. | Aceito pelo autor em 2026-10-25 (objetivo: harmonia com o tema). |
| Um mostrador pode ignorar a opacidade ao pintar a imagem monocromática. | O relógio do desligado sai cheio; o desligado ainda difere do ligado pelas letras vazadas. | Verificado na lista manual; se o desligado e o ligado ficarem indistinguíveis, a spec é reaberta. |
| Slots já configurados podem manter o tipo escolhido antes da atualização do app. | A complication continua colorida até ser recolocada. | A lista manual recoloca a complication antes de verificar; o README orienta. |
| Nenhum dos dois mostradores verificados usa o `SMALL_IMAGE` depois da mudança (se ambos preferirem a monocromática). | R1/R5 não se verificam no colorido. | Procurar na execução da lista um mostrador cujos slots só aceitem `SMALL_IMAGE`; se não houver, R5 se apoia nos testes de unidade e a lista registra o fato. |
| As letras vazadas podem ficar finas demais no tamanho do slot. | Desligado pouco legível. | Revisão visual no relógio. |

## Seções do SoT afetadas

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Estado atual | R1–R6 |
| Arquitetura | R1–R4, R7 |

## Epic invariants that apply

Nenhum — change sem épico.

## Open questions

Nenhuma.
